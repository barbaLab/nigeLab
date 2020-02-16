function c = cat(varargin)
%CAT Concatenation of VideoReader objects.
%
%    See also VIDEOREADER/VERTCAT.
%
%    Copyright 2014 The MathWorks, Inc.

if (nargin == 1)
   c = varargin{1};
else
   error(message('MATLAB:audiovideo:VideoReader:noconcatenation'));
end
