function [summary allreports] = autofitcheck(method,cheatLevel)
if nargin < 1
   method = 'scaffold';
   %method = 'atype';
end
if nargin < 2
    cheatLevel = 2;
end
switch method
    case 'atype'
        molnames = {'myrtenal','nopinone','m_anisaldehyde','angelica','benzaldehyde',...
                    'betapinene','florol','cinnamyl_alcohol','eucalyptus'}; %'1-pentanol' and angelicalactone doesnt work 
    case 'scaffold'
        molnames = {'ethylguiacol','benzOD','myrtenal','nopinone','florol','anisaldehyde','betapinene','m_anisaldehyde'};
end
reports = {};
allkits = {};
numfound = 0;
for i = 1:length(molnames)
  %  try
        fprintf('\n starting molecule: %s method: %s  cheat level: %d\n',molnames{i},method,cheatLevel);
        outputkit = autofit(molnames{i},method,cheatLevel);
        allkits{end+1} = outputkit;
        reports{end+1} = sprintf('%s method %s\n',allkits{end}.allReports,method);
        if length(outputkit.fitlist) > 0
            numfound = numfound+1;
        end
        archivetext(reports{end},'experimentalarchive2.txt');
        close all;
end
allreports = '';
for i = 1:length(reports)
    fprintf('\n%s\n=====================\n', reports{i});
    allreports = sprintf('%s\n%s\n=====================\n', allreports,reports{i});
    displaykitwithfits(allkits{i},1);
end
summary = sprintf('TOTAL %s: %d molecules, %d found\n',method,length(molnames),numfound);
allreports = sprintf('%s\nTOTAL: %d molecules, %d found\n',allreports,length(molnames),numfound);
disp(summary);