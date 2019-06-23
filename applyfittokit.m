function fit = applyfittokit(fit,kit,verbose)
%applyfittokit decides if the fit has preditive power.  returns fields like

%fit.yesvotes: the number of predicted lines
%fit.novotes: the number of lines it is MISSING
%it also makes a list of lines, newassignments, which all the 'upvotes'
%

if nargin < 3
    verbose = 1;
end
fcloseyes = 0.06;
fcloseno = 2.0;

explineset = observablelines(fit,kit);
predictlist = pairlistnearfit(fit);
predictlist = trimpairs(predictlist,explineset.fmin,explineset.fmax);
predictlist = trimweirdpairs(predictlist);
predictlist = trimweakpairs(predictlist);

[upvotes,expfs,newassignments,linepvals] = numpredicted(explineset,predictlist,fit.lines);
[typestring,branchstring,descriptor] = transitiontypes(newassignments);
originallines = pulloriginals(newassignments);  %use these to find ascale,bscale,cscale
ratios = heightratios(originallines);  
newassignments = addscaledheights(newassignments,ratios);

fit.lines = pulloriginals(newassignments);
fit.matches = newassignments;
fit.newassignments = newassignments;
fit.typestring = typestring;
fit.branchstring = branchstring;
fit.branchtypestring = descriptor;
fit.yesvotes = upvotes;
fit.pval = pval(linepvals,fit.numparams);
fit.fitdescriptor = fitdescriptor(fit);
fit.shortdescriptor = shortdescriptor(fit);
if verbose
    disp(fit.fitdescriptor);
end
fit = addhits(fit,kit,expfs);

function p = pval(pvals,numparams)  
%if there are 7 parameters, throw out your best 7 lines, then take the
%rest.

if numparams >= length(pvals)
    p = 1e5;
    return
else
    pvals = sort(pvals);
    p = prod(pvals(numparams+1:end));
end

function linelist = addscaledheights(linelist,ratios)
for i = 1:length(linelist)
    thisline = linelist{i};
    thistype = thisline.transitiontype;
    switch thistype
        case 'a'
            thisline.predictedh = thisline.sixKweakpulsestrength * ratios(1);
        case 'b'
            thisline.predictedh = thisline.sixKweakpulsestrength * ratios(2);
        case 'c'
            thisline.predictedh = thisline.sixKweakpulsestrength * ratios(3);
    end
    linelist{i} = thisline;
end

function ratios = heightratios(linelist)
outputs = extractfieldsfromcellarray(linelist,{'transitiontype','sixKweakpulsestrength','expheight'});
ctypes = outputs.transitiontype;
for i = 1:length(ctypes)
    types(i) = ctypes{i}(1);
end
unscaledh = outputs.sixKweakpulsestrength;
exphs = outputs.expheight;
ascale = 0;
bscale = 0;
cscale = 0;

isa = find(types == 'a');
isb = find(types == 'b');
isc = find(types == 'c');
if length(isa) > 0
    ascale = mean(exphs(isa)) / mean(unscaledh(isa));
end
if length(isb) > 0
    bscale = mean(exphs(isb)) / mean(unscaledh(isb));
end
if length(isc) > 0
    cscale = mean(exphs(isc)) / mean(unscaledh(isc));
end
ratios = [ascale bscale cscale];

function originals = pulloriginals(linelist)
originals = {};
isold = extractonefieldfromcellarray(linelist,'inoldfit');
oldi = find(isold == 1);
for i = 1:length(oldi)
    originals{i} = linelist{oldi(i)};
end

function s = shortdescriptor(fit)
s = sprintf('FOUND: [%3.2f %3.2f %3.2f] %d upvotes',fit.ABC(1),fit.ABC(2),fit.ABC(3),fit.yesvotes);

function s = fitdescriptor(fit)
if isfield(fit,'pattern')
    s = sprintf('FOUND: [%3.2f %3.2f %3.2f] %d upvotes, pattern %d, pattern p=%3.1e,fit p = %3.1e',fit.ABC(1),fit.ABC(2),fit.ABC(3),fit.yesvotes,fit.pattern.attemptIndex,fit.pattern.pval,fit.pval);
else
    s = sprintf('F:[%3.2f %3.2f %3.2f] %d upvotes,fit p = %3.1e',fit.ABC(1),fit.ABC(2),fit.ABC(3),fit.yesvotes,fit.pval);
end

function [typestring,branchstring,descriptor] = transitiontypes(pairlist)
outputs = extractfieldsfromcellarray(pairlist,{'transitiontype','delj'});
types = outputs.transitiontype;
deljs = outputs.delj;

typestring = '';
branchstring = '';
for i = 1:length(pairlist)
    typestring = [typestring types{i}];
    if deljs(i) == 0
        branchstring = [branchstring 'Q'];
    elseif abs(deljs(i)) == 1
        branchstring = [branchstring 'R'];
    else
        branchstring = [branchstring 'X'];
    end
end
descriptor = sprintf('%s\n%s',typestring,branchstring);
        

function [upvotes,expfs,newpairs,psthatworked] = numpredicted(explineset,predictlist,lineset)
assignedfs = [];
assignedis = [];
assignedps = [];
hashlist = extractonefieldfromcellarray(lineset,'hash');
for i = 1:length(predictlist)
    thispair = predictlist{i};
    predictf = thispair.delf;
    [fs,errs,ivals] = closestf(predictf,explineset.fs,3);
    if ((errs(1) < explineset.fthreshold)) && (errs(1) < errs(end)/10)  %we have a match!
        assignedfs(end+1) = fs(1);
        assignedis(end+1) = i;
        errs = errs + .001;
        thispair.pval = 5 * errs(1)/mean(errs);
        thispair.expfreq = fs(1);
        thispair.expheight = explineset.hs(ivals(1));
        thispair.theoryf = predictf;
        thispair.unstretchedpredictedf = predictf;
        thispair = updateline(thispair);
        if ismember(thispair.hash,hashlist)
            thispair.inoldfit = 1;
        else
            thispair.inoldfit = 0;
        end
        predictlist{i} = updateline(thispair);
       % assignedps(end+1) = 5 * errs(1)/mean(errs);
    end
end  %later pull out assignedfs which are unique, like in boggle.  THOSE are true matches.
[expfs,whichworked] = bogglefs(assignedfs);
pairsthatworked = assignedis(whichworked);
newpairs = selectcells(predictlist,pairsthatworked);
newpairs = assignfstopairs(newpairs,expfs);
newpairs = sortcellarraybyfield(newpairs,'pval');
psthatworked = extractonefieldfromcellarray(newpairs,'pval');
upvotes = length(unique(assignedfs));

function pairs = assignfstopairs(pairs,expfs)
for i = 1:length(pairs)
    thispair = pairs{i};
    thispair.expf = expfs(i);
    pairs{i} = thispair;
end
    
function pairlist = pairlistnearfit(fit)
%calls SPCAT to return a list of pairs in and near the fit
argsin = fit.info.argsout;
jmin = fit.info.minj - 2;
jmax = fit.info.maxj + 4;
argsin.hasa = 1;
argsin.hasb = 1;
argsin.hasc = 1;

pairlist = spcatjrange(argsin,jmin,jmax,0,jmax);  %just do all k seems more stable

function fit = addhits(fit,kit,expfs)
%goes back to the experimental onedpeakfs, finds them, adds the lines.
%helps with plotting
hitis = [];
for ii = 1:length(expfs)
    [f,err,i] = closestf(expfs(ii),kit.onedpeakfs,1);
    hitis(end+1) = i;
end
fit.hitis = hitis;
fit.hitfs = kit.onedpeakfs(fit.hitis);
fit.hiths = kit.onedpeakhs(fit.hitis);
    
function explineset = observablelines(fit,kit)
expfs = extractonefieldfromcellarray(fit.lines,'expfreq');
fit = addhits(fit,kit,expfs);

fcloseyes = 0.06;
explineset.hthresh = min(fit.hiths)/4;
%explineset.hthresh = min(fit.pattern.allhs)/4;

usablei = find(kit.onedpeakhsunassigned > explineset.hthresh);
explineset.fs = kit.onedpeakfsunassigned(usablei);
explineset.hs = kit.onedpeakhsunassigned(usablei);

[explineset.fs,XI] = sort(explineset.fs);
explineset.hs = explineset.hs(XI);

explineset.fmin = min(explineset.fs) + 50;
explineset.fmax = max(explineset.fs) - 50;
explineset.meanspacing = (explineset.fmax - explineset.fmin) / length(explineset.fs);
explineset.fthreshold = max(fcloseyes,explineset.meanspacing / 20);




