function flag = hasFrame(obj)
%HASFRAME Determine if there is a frame available to read from a video file
%
%   FLAG = HASFRAME(OBJ) returns TRUE if there is a video frame available
%   to read from the file. If not, it returns FALSE.
%
%   Example:
%       % Construct a multimedia reader object associated with file
%       'xylophone.mp4'.
%       vidObj = VideoReader('xylophone.mp4');
%
%       % Specify that reading should start at 0.5 seconds from the
%       % beginning.
%       vidObj.CurrentTime = 0.5;
%
%       % Create an axes
%       currAxes = axes;
%       
%       % Read video frames until available
%       while hasFrame(vidObj)
%           vidFrame = readFrame(vidObj);
%           image(vidFrame, 'Parent', currAxes);
%           currAxes.Visible = 'off';
%           pause(1/vidObj.FrameRate);
%       end
%
%   See also AUDIOVIDEO, MOVIE, VIDEOREADER,VIDEOREADER/READFRAME, MMFILEINFO.

%    Copyright 2013-2014 The MathWorks, Inc.

if obj.IsFrameBased
    error( message('MATLAB:audiovideo:VideoReader:NotSupportedFramesCounted', 'HASFRAME', 'HASFRAME') );
end

% ensure that we pass in only 1 argument
narginchk(1, 1);

% ensure that we pass out only 1 output argument
nargoutchk(0, 1);

obj.IsStreamingBased = true;

try
    flag = hasFrame( getImpl(obj) );
catch ME
    nigeLab.libs.VideoReader.handleImplException(ME);
end