function flag = linkToData(blockObj,suppressWarning)
%% LINKTODATA  Connect the data saved on the disk to the structure
%
%  b = nigeLab.Block;
%  flag = linkToData(b); 
%  linkToData(b,true) % suppress warnings
%
%  linkToData(b,'Raw');   % only link 'Raw' field
%
%  linkToData(b,{'Raw','Filt','AnalogIO'}); % only link 'Raw','Filt',and
%                                           % 'AnalogIO' fields
%
% flag returns true if something was not "linked" correctly. Using the flag
% returned by nigeLab.Block.linkField, this method issues warnings if not
% all the files are found during the "link" process.

%% DEFAULTS
flag = false;

% If not otherwise specified, assume extraction has not been done.
if nargin < 2
   suppressWarning = false;
   field = blockObj.Fields;
else
   switch class(suppressWarning)
      case 'char'
         field = {suppressWarning};
         f = intersect(field,blockObj.Fields);
         if isempty(f)
            error(['nigeLab:' mfilename ':badInputType2'],...
               'Invalid field: %s (%s)',field{:},blockObj.Name);
         end
         field = f;
         suppressWarning = true;
      case 'cell'
         field = suppressWarning;
         f = intersect(field,blockObj.Fields);
         if isempty(f)
            error(['nigeLab:' mfilename ':badInputType2'],...
               'Invalid field: %s (%s)',field{:},blockObj.Name);
         end
         field = f;
         suppressWarning = true;
      case 'logical'
         field = blockObj.Fields;
      otherwise
         error(['nigeLab:' mfilename ':badInputType2'],...
            'Unexpected class for ''suppressWarning'': %s',...
            class(suppressWarning));
   end
end

%% ITERATE ON EACH FIELD AND LINK THE CORRECT DATA TYPE
N = numel(field);
warningRef = false(1,N);
warningFold = false(1,N);
for ii = 1:N
   fieldIndex = find(ismember(blockObj.Fields,field{ii}),1,'first');
   if isempty(fieldIndex)
      error(['nigeLab:' mfilename ':invalidField'],...
         'Invalid field: %s (%s)',field{ii},blockObj.Name);
   end
   pcur = parseFolder(blockObj,fieldIndex);
   if exist(pcur,'dir')==0
      warningFold(ii) = true;
   elseif isempty(dir([pcur filesep '*.mat']))
       warningRef(ii) = true;
   else
       warningRef(ii) = blockObj.linkField(fieldIndex);
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
      fieldIndex = find(ismember(blockObj.Fields,field{warningIdx(ii)}),...
         1,'first');
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
         '\t%s\t-> Could not find all %s data files.\n',...
         blockObj.Name,field{warningIdx(ii)});
   end
end
blockObj.updateStatus('notify'); % Just emits the event in case listeners
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

