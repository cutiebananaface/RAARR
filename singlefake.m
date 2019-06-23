function singlefake(method,randseed)

if nargin == 0
    method = 'scaffold';
    randseed = 1;
end
rng(randseed);
ts = settingsfromtightness(1);
ts.maxcomponents = 1;
ts.numjguess = 2;
ts.ladderSearchtimes = {[20, 1e-30],[100,1e-20],[500,1e-8],[2000,100]};
ts.maxka = 2;
ts.lines = [1];

molstats = loadmol('generic');
    molstats.a = 5000;
    molstats.b = 2000; % in units of MHz
    molstats.c = 1800;  
    molstats.DK = 0;
    molstats.DJK = 0; % distortion constants in units of MHz
    molstats.DJ = 0;
    molstats.deltaK = 0;
    molstats.deltaJ = 0;

    molstats.frange = [12000 25000];
    molstats = updatemolstats(molstats);
        
        pgofilename = makefakepgofile(molstats, molstats.molname);
        csvfilename = makefakecsv(molstats);
        %csvfilename = '../squareassign/Molecules/fakes/fakegeneric.csv';
      
        ts = settingsfromtightness(1);
        ts.evolveFit = 0;
        ts.addisotopes = 0;
        ts.patternfitting.maxpatterns = 1;
        ts.lines = 15105;
        
        [kit] = autofit(csvfilename,method,0,1,ts);%franges{i});%,tightmodes(i));
        if isstruct(kit.latestpattern)
%                pvals(end+1) = kit.latestpattern.pval;
            showseriessquare(kit.latestpattern.archive);
            cmdline = ['../pgofiles/pgopher ' pgofilename ' ' csvfilename '&'];
            system(cmdline);
        end


end

