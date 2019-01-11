function flag = linkToData(blockObj,suppressWarning)
%% LINKTODATA  Connect the data saved on the disk to the structure
%
%  b = nigeLab.Block;
%  flag = linkToData(b); % linkToData(b,true) % suppress warnings
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% DEFAULTS
flag = false;

% If not otherwise specified, assume extraction has not been done.
if nargin < 2
   suppressWarning = false;
end

%% ITERATE ON EACH FIELD AND LINK THE CORRECT DATA TYPE
N = numel(blockObj.Fields);
warningRef = false(1,N);
for fieldIndex = 1:N
   warningRef(fieldIndex) = blockObj.linkField(fieldIndex);
end

%% GIVE USER WARNINGS
if any(warningRef) && ~suppressWarning
   warningIdx = find(warningRef);
   warning(sprintf(['Double-check that data files are present. \n' ...
                    'Consider re-running doExtraction.\n'])); %#ok<SPWRN>
   for ii = 1:numel(warningIdx)
      fprintf(1,'\t-> Could not find all %s data files.\n',...
         blockObj.Fields{warningIdx(ii)});
   end
end

blockObj.save;
flag = true;
end

