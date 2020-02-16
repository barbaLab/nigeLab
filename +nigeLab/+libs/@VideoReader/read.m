function varargout = read(obj, index, outputformat)
%READ Read a video file. 
%   READ will be removed in a future release. Use READFRAME instead.
%
%   VIDEO = READ(OBJ) reads in all video frames from the file associated 
%   with OBJ.  VIDEO is an H x W x B x F matrix where:
%         H is the image frame height
%         W is the image frame width
%         B is the number of bands in the image (e.g. 3 for RGB),
%         F is the number of frames read
%   The class of VIDEO depends on the data in the file. 
%   For example, given a file that contains 8-bit unsigned values 
%   corresponding to three color bands (RGB24), video is an array of 
%   uint8 values.
%
%   VIDEO = READ(OBJ,INDEX) reads only the specified frames. INDEX can be 
%   a single number or a two-element array representing an INDEX range 
%   of the video stream.  Use Inf to represent the last frame of the file.
%
%   For example:
%
%      VIDEO = READ(OBJ, 1);        % first frame only
%      VIDEO = READ(OBJ, [1 10]);   % first 10 frames
%      VIDEO = READ(OBJ, Inf);      % last frame only
%      VIDEO = READ(OBJ, [50 Inf]); % frame 50 thru end
%
%   If an invalid INDEX is specified, MATLAB throws an error.
%
%   VIDEO = READ(___,'native') always returns data in the format specified 
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
%        'RGB24'            uint8         MxNx3xF       RGB24 image
%        'Grayscale'        uint8         MxNx1xF       Grayscale image
%        'Indexed'          uint8         MxNx3xF       RGB24 image
%
%     VIDEO Output Formats (using 'native'):
%
%       obj.VideoFormat   Data Type   VIDEO Dimensions  Description
%       ---------------   ---------   ----------------  ------------------
%        'RGB24'            uint8         MxNx3xF       RGB24 image
%        'Grayscale'        struct        1xF           MATLAB movie*
%        'Indexed'          struct        1xF           MATLAB movie*
%
%     Motion JPEG 2000 VIDEO Output Formats (using default or 'native'):
%                             
%       obj.VideoFormat   Data Type   VIDEO Dimensions  Description
%       ---------------   ---------   ----------------  ------------------
%        'Mono8'            uint8         MxNx1xF       Mono image
%        'Mono8 Signed'     int8          MxNx1xF       Mono signed image
%        'Mono16'           uint16        MxNx1xF       Mono image
%        'Mono16 Signed'    int16         MxNx1xF       Mono signed image
%        'RGB24'            uint8         MxNx3xF       RGB24 image
%        'RGB24 Signed'     int8          MxNx3xF       RGB24 signed image
%        'RGB48'            uint16        MxNx3xF       RGB48 image
%        'RGB48 Signed'     int16         MxNx3xF       RGB48 signed image
%
%     *A MATLAB movie is an array of FRAME structures, each of
%      which contains fields cdata and colormap.
%
%   Example:
%      % Construct a multimedia reader object associated with file 
%      % 'xylophone.mp4'.
%      readerobj = VideoReader('xylophone.mp4');
%
%      % Read in all video frames.
%      vidFrames = read(readerobj);
%
%      % Get the number of frames.
%      numFrames = get(readerobj, 'numberOfFrames');
%
%      % Create a MATLAB movie struct from the video frames.
%      for k = 1 : numFrames
%            mov(k).cdata = vidFrames(:,:,:,k);
%            mov(k).colormap = [];
%      end
%
%      % Create a figure
%      hf = figure; 
%      
%      % Resize figure based on the video's width and height
%      set(hf, 'position', [150 150 readerobj.Width readerobj.Height])
%
%      % Playback movie once at the video's frame rate
%      movie(hf, mov, 1, readerobj.FrameRate);
%
%   See also AUDIOVIDEO, MOVIE, VIDEOREADER, VIDEOREADER/READFRAME, VIDEOREADER/HASFRAME, MMFILEINFO.

%    NCH DTL
%    Copyright 2005-2017 The MathWorks, Inc.

if length(obj) > 1
    error(message('MATLAB:audiovideo:VideoReader:nonscalar'));
end

% ensure that we pass in 1, 2 or 3 arguments only
narginchk(1, 3);

% ensure that we pass out only 1 output argument
nargoutchk(0, 1);

% Verify that the index argument is of numeric type
if nargin < 2
    index = [1 inf];
    outputformat = 'default';
elseif nargin < 3 && ischar(index)
    outputformat = index;
    index = [1 inf];
elseif nargin < 3
    outputformat = 'default';
end

validateattributes( ...
    index, ...
    {'numeric'}, {'vector'}, ...
    'nigeLab.libs.VideoReader.read', 'index');
index = double(index);

try
    outputformat = nigeLab.libs.VideoReader.validateOutputFormat(outputformat, 'nigeLab.libs.VideoReader.read');
catch ME
    throwAsCaller(ME);
end

if obj.IsStreamingBased
    error( message('MATLAB:audiovideo:VideoReader:ReadNotAllowed') );
end

warnState = warning('off', 'MATLAB:audiovideo:VideoReader:unknownNumFrames');
oc = onCleanup( @() warning(warnState) );

% Frame-based operations need to know the NumberOfFrames before reading.
% As frame-counting is not performed during object construction, it has to
% be performed before the first call to read.
numFrames = get(obj, 'NumberOfFrames');

try
    if nargin == 1
        frameIndex = [1 Inf];
        % Dimensions of data returned is HxWx3xN
        videoFrames = read(getImpl(obj));
    elseif nargin >= 2
        % Dimensions of data returned is HxWx3xN
        videoFrames = read(getImpl(obj), index);
        if isscalar(index)
            frameIndex = [index index];
        else
            frameIndex = index;
        end
    end
catch err
    nigeLab.libs.VideoReader.handleImplException(err);
end

% Update the frameIndex only if the total number of frames in the video can
% be determined after the read operation
if( ~isempty( numFrames ) )
    frameIndex(frameIndex == Inf) = numFrames;
end

% Check that read was complete only if the frame indices to be read have
% been accurately determined.
if ~any(frameIndex == Inf)
    checkIncompleteRead(size(videoFrames, 4), frameIndex);
end

videoFrames = nigeLab.libs.VideoReader.convertToOutputFormat( videoFrames, ...
                                                 get(obj, 'VideoFormat'), ...
                                                 outputformat, ...
                                                 get(getImpl(obj), 'colormap'));

% Video is the output argument.
varargout{1} = videoFrames;

obj.IsFrameBased = true;

end

function checkIncompleteRead(actNum, index)
expNum = index(2) - index(1) + 1;
if actNum < expNum
    warning(message('MATLAB:audiovideo:VideoReader:incompleteRead', ...
        index(1), index(1)+actNum-1));
end
end
