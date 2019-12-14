function fileType = getFileType(blockObj,field)
%% GETFILETYPE       Return file type corresponding to that field
%
%  fileType = blockObj.getFileType(field);
%
%  --------
%   INPUTS
%  --------
%  blockObj       :     nigeLab.Block class object.
%
%    field        :     String corresponding element of Fields property in
%                          blockObj.
%
%  --------
%   OUTPUT
%  --------
%   fileType         :     File type {'Hybrid';'MatFile';'Event'}
%                          corresponding to files associated with that
%                          field.
%
% By: Max Murphy & Federico Barban MAECI 2019 Collaboration

%% DEFAULTS
N_CHARS_TO_COMPARE = 7;

%% Simple code but for readability
idx = strncmpi(blockObj.Fields,field,N_CHARS_TO_COMPARE);
if sum(idx) == 0
   error('Not a valid field name: %s',field);
end
fileType = blockObj.FileType{idx};


end