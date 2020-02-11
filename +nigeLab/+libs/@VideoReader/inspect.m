function inspect(obj)
%INSPECT Open the inspector and inspect VideoReader object properties.
%
%    INSPECT(OBJ) opens the property inspector and allows you to
%    inspect and set properties for the VideoReader object, OBJ.
%
%    Example:
%        r = VideoReader('myfilename.avi');
%        inspect(r);

%    NCH DTL
%    Copyright 2004-2013 The MathWorks, Inc.

if length(obj) > 1
    error(message('MATLAB:audiovideo:VideoReader:nonscalar'));
end

% If called from Workspace Browser (openvar), error, so that the Variable
% Editor will be used. If called directly, warn, and bring up the Inspector.
stack = dbstack();
if any(strcmpi({stack.name}, 'openvar'))
    error(message('MATLAB:audiovideo:VideoReader:inspectObsolete'));
else
    warning(message('MATLAB:audiovideo:VideoReader:inspectObsolete'));
    inspect(obj.getImpl());
end
