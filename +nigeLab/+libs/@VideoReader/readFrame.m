function varargout = readFrame(obj, outputformat)
%READFRAME Read the next available frame from a video file
%
%   VIDEO = READFRAME(OBJ) reads the next available video frame from the
%   file associated  with OBJ.  VIDEO is an H x W x B matrix where:
%         H is the image frame height
%         W is the image frame width
%         B is the number of bands in the image (e.g. 3 for RGB)
%   The class of VIDEO depends on the data in the file. 
%   For example, given a file that contains 8-bit unsigned values 
%   corresponding to three color bands (RGB24), video is an array of 
%   uint8 values.
%
%   VIDEO = READ(OBJ,'native') always returns data in the format specified 
%   by the VideoFormat property, and can include any of the input arguments
%   in previous syntaxes.  See 'Output Formats' section below.
%
%   Output Formats
%   VIDEO is returned in different formats depending upon the usage of the
%   'native' parameter, and the value of the obj.VideoFormat property:
%
%     VIDEO Output Formats (default behavior):
%                             
%       obj.VideoFormat   Data Type   VIDEO Dimensions  Description
%       ---------------   ---------   ----------------  ------------------
%        'RGB24'            uint8         MxNx3         RGB24 image
%        'Grayscale'        uint8         MxNx1         Grayscale image
%        'Indexed'          uint8         MxNx3         RGB24 image
%
%     VIDEO Output Formats (using 'native'):
%
%       obj.VideoFormat   Data Type   VIDEO Dimensions  Description
%       ---------------   ---------   ----------------  ------------------
%        'RGB24'            uint8         MxNx3         RGB24 image
%        'Grayscale'        struct        1x1           MATLAB movie*
%        'Indexed'          struct        1x1           MATLAB movie*
%
%     Motion JPEG 2000 VIDEO Output Formats (using default or 'native'):
%                             
%       obj.VideoFormat   Data Type   VIDEO Dimensions  Description
%       ---------------   ---------   ----------------  ------------------
%        'Mono8'            uint8         MxNx1         Mono image
%        'Mono8 Signed'     int8          MxNx1         Mono signed image
%        'Mono16'           uint16        MxNx1         Mono image
%        'Mono16 Signed'    int16         MxNx1         Mono signed image
%        'RGB24'            uint8         MxNx3         RGB24 image
%        'RGB24 Signed'     int8          MxNx3         RGB24 signed image
%        'RGB48'            uint16        MxNx3         RGB48 image
%        'RGB48 Signed'     int16         MxNx3         RGB48 signed image
%
%     *A MATLAB movie is an array of FRAME structures, each of
%      which contains fields cdata and colormap.
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
%   See also AUDIOVIDEO, MOVIE, VIDEOREADER,VIDEOREADER/HASFRAME, MMFILEINFO.

%    Copyright 2013-2017 The MathWorks, Inc.

if length(obj) > 1
    error(message('MATLAB:audiovideo:VideoReader:nonscalar'));
end

% ensure that we pass in 1 or 2 arguments only
narginchk(1, 2);

% ensure that we pass out only 1 output argument
nargoutchk(0, 1);

if nargin < 2
    outputformat = 'default';
end

try
    outputformat = nigeLab.libs.VideoReader.validateOutputFormat(outputformat, 'nigeLab.libs.VideoReader.readFrame');
catch ME
    throwAsCaller(ME);
end

if obj.IsFrameBased
    error( message('MATLAB:audiovideo:VideoReader:NotSupportedFramesCounted', 'READFRAME', 'READFRAME') );
end

readFrameOC = onCleanup( @() set(obj, 'IsStreamingBased', 'true') );

if ~hasFrame(obj)
    error(message('MATLAB:audiovideo:VideoReader:EndOfFile'));
end

try
    videoFrame = readFrame( getImpl(obj) );
catch exception
    nigeLab.libs.VideoReader.handleImplException(exception);
end

varargout{1} = nigeLab.libs.VideoReader.convertToOutputFormat( videoFrame, ...
                                                  get(obj, 'VideoFormat'), ...
                                                  outputformat, ...
                                                  get(getImpl(obj), 'colormap') );
                                              