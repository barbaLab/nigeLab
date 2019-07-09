function fType = getFileType(blockObj,field)
%% GETFILETYPE       Return file type corresponding to that field
%
%  fType = blockObj.getFileType(field);
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
%   fType         :     File type {'Hybrid';'MatFile';'Event'}
%                          corresponding to files associated with that
%                          field.
%
% By: Max Murphy & Federico Barban MAECI 2019 Collaboration

%% DEFAULTS
N_CHARS_TO_COMPARE = 7;

%% Simple code but for readability
fType = blockObj.FileType{strncmpi(blockObj.Fields,field,N_CHARS_TO_COMPARE)};


end