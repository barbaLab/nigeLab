function c = horzcat(varargin)
%HORZCAT Horizontal concatenation of VideoReader objects.
%
%    See also VIDEOREADER/VERTCAT.

%    JCS DTL
%    Copyright 2004-2013 The MathWorks, Inc.

if (nargin == 1)
   c = varargin{1};
else
   error(message('MATLAB:audiovideo:VideoReader:noconcatenation'));
end
