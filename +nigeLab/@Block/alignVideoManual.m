function fig = alignVideoManual(blockObj,digStreamInfo,vidStreamName)
% ALIGNVIDEOMANUAL  Manually obtain offset between video and neural record,
%                    using specific streams from the digital record that
%                    are overlayed on top of streams parsed from the video
%                    record.
%
%  blockObj.alignVideoManual();
%  blockObj.alignVideoManual(digStreamName,vidStreamName);
%
%  --------
%   INPUTS
%  --------
%  digStreamName  :  Stream field 'custom_channel_name' 
%                     --> Given as struct array, where field elements are
%                          (for example):
%                       digStreamInfo(k).field = 'DigIO' or 'AnalogIO'
%                       digStreamInfo(k).name =  'Beam';
%                       --> 'name' matches 'custom_channel_name' field
%
%  vidStreamName  :  Name field of 'signal' for blockObj.Videos.at(k),
%                    where the k-th field has the name corresponding to
%                    that element of "vidStreamName"
%                       --> e.g. 'Paw_Likelihood'
%                       Should only use one Video Stream Name so it can
%                       only be a single character array, not a cell array.
%                       * Will be plotted as a marker stream representing
%                       data synchronized with the video record, which can
%                       be "dragged" to properly overlay with the digital
%                       record while visually ensuring that the new
%                       synchronization makes sense by watching the video
%                       at key transitions in both sets of streams. *
%
%  --------
%   OUTPUT
%  --------
%  Saves a file in OUT_DIR that contains "VideoStart" variable, which is a
%  scalar that relates the relative time of the neural data to the onset of
%  the video (i.e. if the neural recording was started, then video started
%  30 seconds later, VideoStart would have a value of +30).
%
% By: Max Murphy  v2.1  08/29/2018  Changed alignment method from toggling
%                                   using the "o" key to just click and
%                                   drag the red (beam break) trace and
%                                   line it up however looks best against
%                                   the blue one.
%
%                 v2.0  08/17/2018  Made a lot of changes from previous
%                                   version, which had a different name as
%                                   well.

if nargin < 3
   vidStreamName = [];
end

if nargin < 2
   digStreamName = [];
end


% Parse digStreamName input
if isempty(digStreamName)
   
end


% Parse vidStreamName input
opts = getName(blockObj.Videos,'vidstreams');
if ~iscell(opts)
   opts = {opts};
end
if isempty(vidStreamName)
   vidStreamName = nigeLab.utils.uidropdownbox('Select Vid Stream',...
      'Video Stream to Use',opts);
end
strIdx = find(ismember(opts,vidStreamName),1,'first');




% PARSE FILE NAMES
Name = strsplit(FNAME,BEAM_ID);
Name = Name{1};

% PARSE VIDEO FILES / LOCATION
% Check in several places for the video files...
vid_F = dir(fullfile(VID_DIR,[Name '*' VID_TYPE]));

if isempty(vid_F)
   fprintf(1,'No videos in\n->\t%s\n',VID_DIR);
   
   fprintf(1,'Checking location with _Beam.mat...');
   % Check for videos in same location as other files
   vid_F = dir(fullfile(DIR,[Name '*' VID_TYPE]));
   
   if isempty(vid_F) % Maybe they are in some other, unspecified directory?
      fprintf(1,'unsuccessful.\n');
      VID_DIR = inputdlg({['Bad video directory. ' ...
         'Specify VID_DIR here (change variable for next time).']},...
         'Invalid VID_DIR path',1,{ALT_VID_DIR});
      if isempty(VID_DIR)
         error('No valid video directory specified. Script canceled.');
      else
         VID_DIR = VID_DIR{1};
      end
      vid_F = dir(fullfile(VID_DIR,[Name '*' VID_TYPE]));
      
      if isempty(vid_F) % If there are still no files something else wrong
         disp('No video file located!');
         error('Please check VID_DIR or missing video for that session.');
      end
   else
      fprintf(1,'successful!\n');
   end
end

% MAKE STRUCT OF FILE LOCATIONS

% All potential data streams or data files
dat_F = struct('streams',struct(...
   'beam',struct('folder',DIR,'name',[Name BEAM_ID '.mat']),...
   'press',struct('folder',DIR,'name',[Name PRESS_ID '.mat']),...
   'paw',struct('folder',DIR,'name',[Name PAW_ID '.mat'])),...
   'scalars',struct(...
   'guess',struct('folder',DIR,'name',[Name GUESS_ID '.mat']),...
   'alignLag',struct('folder',DIR,'name',[Name OUT_ID '.mat'])));



% CONSTRUCT UI
fig=figure('Name','Bilateral Reach Scoring',...
   'Color','k',...
   'NumberTitle','off',...
   'MenuBar','none',...
   'ToolBar','none',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.8],...
   'UserData',struct('flag',false,'h',[]));

% Panel for displaying information text
dispPanel = uipanel(fig,'Units','Normalized',...
   'BackgroundColor','k',...
   'Position',[0 0.25 1 0.75]);


% CONSTRUCT CUSTOM CLASS OBJECTS
% Make video alignment information object
alignInfoObj = alignInfo(fig,dat_F);

% Make video frame object to track video frames
vidInfoObj = vidInfo(fig,dispPanel,vid_F);
vidInfoObj.setOffset(alignInfoObj.alignLag);

% Make listener object to integrate class information
graphicsUpdateObj = graphicsUpdater(vid_F,{'alignment'});
graphicsUpdateObj.addListeners(vidInfoObj,alignInfoObj);

% Construct video selection interface and load video
graphics = vidInfoObj.getGraphics;
graphicsUpdateObj.addGraphics(graphics);
vidInfoObj.buildVidSelectionList;

% Add associated graphics objects to listener
graphics = alignInfoObj.getGraphics;
graphicsUpdateObj.addGraphics(graphics);
graphics = vidInfoObj.getGraphics;
graphicsUpdateObj.addGraphics(graphics);

% SET HOTKEY AND MOUSE MOVEMENT FUNCTIONS
set(fig,'KeyPressFcn',{@hotKey,vidInfoObj,alignInfoObj});
set(fig,'WindowButtonMotionFcn',{@trackCursor,alignInfoObj});
 
% Function for tracking cursor
   function trackCursor(src,~,a)
      a.setCursorPos(src.CurrentPoint(1,1));  
   end

% Function for hotkeys
   function hotKey(~,evt,v,a)
      switch evt.Key     
         case 's' % Press 'alt' and 's' at the same time to save
            if strcmpi(evt.Modifier,'alt')
               a.saveAlignment;
            end
            
         case 'a' % Press 'a' to go back one frame
            v.retreatFrame(1);
            
         case 'leftarrow' % Press 'leftarrow' key to go back 5 frames
            v.retreatFrame(5);
            
         case 'd' % Press 'd' to go forward one frame
            v.advanceFrame(nan,nan);
            
         case 'rightarrow' % Press 'rightarrow' key to go forward one frame
            v.advanceFrame(nan,nan);
            
         case  'subtract' % Press numpad '-' key to zoom out on time series
            a.zoomOut;
            
         case 'add' % Press numpad '+' key to zoom in on time series
            a.zoomIn;
            
         case 'space' % Press 'spacebar' key to play or pause video
            v.playPauseVid;
      end
   end
end