function obj = loadobj(obj)
%LOADOBJ Load filter for VideoReader objects.
%
%    OBJ = LOADOBJ(OBJ) is called by LOAD when an VideoReader object is 
%    loaded from a .MAT file. The return value, OBJ, is subsequently 
%    used by LOAD to populate the workspace.  
%
%    LOADOBJ will be separately invoked for each object in the .MAT file.
%

%    NH DT DL
%    Copyright 2010-2013 The MathWorks, Inc.

% Object is already created, just properly initialize it.
% We do this to take advantage of all the load functionality provided
% by MATLAB (e.g. object recursion detection).

obj.init(obj.LoadArgs{:});

end

