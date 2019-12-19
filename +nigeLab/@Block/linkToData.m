function flag = linkToData(blockObj,suppressWarning)
%% LINKTODATA  Connect the data saved on the disk to the structure
%
%  b = nigeLab.Block;
%  flag = linkToData(b); 
%  linkToData(b,true) % suppress warnings
%
% flag returns true if something was not "linked" correctly. Using the flag
% returned by nigeLab.Block.linkField, this method issues warnings if not
% all the files are found during the "link" process.

%% DEFAULTS
flag = false;

% If not otherwise specified, assume extraction has not been done.
if nargin < 2
   suppressWarning = false;
end

%% ITERATE ON EACH FIELD AND LINK THE CORRECT DATA TYPE
N = numel(blockObj.Fields);
warningRef = false(1,N);
warningFold = false(1,N);
for fieldIndex = 1:N
   pcur = parseFolder(blockObj,fieldIndex);
   if exist(pcur,'dir')==0
      warningFold(fieldIndex) = true;
   elseif isempty(dir([pcur filesep '*.mat']))
       warningRef(fieldIndex) = true;
   else
       warningRef(fieldIndex) = blockObj.linkField(fieldIndex);
   end
end

%% GIVE USER WARNINGS
% Notify user about potential missing folders:
if any(warningFold)
   warningIdx = find(warningFold);
   nigeLab.utils.cprintf('UnterminatedStrings',...
                         'Some folders are missing. \n'); 
   nigeLab.utils.cprintf('text',...
                         '\t-> Rebuilding folder tree ... %.3d%%',0);
   for ii = 1:numel(warningIdx)
      pcur = parseFolder(blockObj,fieldIndex);
      [~,~,~] = mkdir(pcur);
      fprintf(1,'\b\b\b\b%.3d%%',round(100*ii/sum(warningFold)));
   end
   fprintf(1,'\n');
end

% If any element of a given "Field" is missing, warn user that there is a
% missing data file for that particular "Field":
if any(warningRef) && ~suppressWarning
   warningIdx = find(warningRef);
   nigeLab.utils.cprintf('UnterminatedStrings',...
      ['Double-check that data files are present. \n' ...
       'Consider re-running doExtraction.\n']);
   for ii = 1:numel(warningIdx)
      nigeLab.utils.cprintf('text',...
         '\t-> Could not find all %s data files.\n',...
         blockObj.Fields{warningIdx(ii)});
   end
end

blockObj.save;
flag = true;

% Local function to return folder path
   function [pcur,p] = parseFolder(blockObj,idx)
      % PARSEFOLDER  Local function to return correct folder location
      %
      %  [pcur,p] = parseFolder(blockObj,fieldIndex);
      
      % Existing name of folder, from "Paths:"
      p = blockObj.Paths.(blockObj.Fields{idx}).dir;
      % Current path, depending on local or remote status:
      pcur = nigeLab.utils.getUNCPath(p); 
   end

end

