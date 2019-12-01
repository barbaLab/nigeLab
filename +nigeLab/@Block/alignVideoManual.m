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

%% Parse inputs
if nargin < 3
   vidStreamName = [];
end

if nargin < 2
   digStreamName = [];
end

% Parse digStreamName input
if isempty(digStreamName)
   [title_str,prompt_str,opts] = nigeLab.utils.getDropDownRadioStreams(blockObj);
   str = 'Yes';
   digInfo = struct('name',[],'field',[],'idx',[]);
   k = 0;
   while strcmp(str,'Yes')
      k = k + 1;
      [digInfo(k).name,digInfo(k).field,digInfo(k).idx] = ...
         nigeLab.utils.uidropdownradiobox(...
            title_str,...
            prompt_str,...
            opts,true);
      str = nigeLab.utils.uidropdownbox({'Selection Option Window';...
         'Select More Streams?'},...
         'Add Streams?',{'No','Yes'},true);
      opts{digInfo(k).idx(1,1),1} = setdiff(opts{digInfo(k).idx(1,1),1},...
         digInfo(k).name);
   end
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

%% Build graphics

% CONSTRUCT UI
fig=figure('Name','Bilateral Reach Scoring',...
   'Color',nigeLab.defaults.nigelColors('background'),...
   'NumberTitle','off',...
   'MenuBar','none',...
   'ToolBar','none',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.8],...
   'UserData',struct('flag',false,'h',[]));

% Panel for displaying information text
backgroundPanel = nigeLab.libs.nigelPanel(fig,...
            'String',strrep(blockObj.Name,'_','\_'),...
            'Tag','dispPanel',...
            'Units','normalized',...
            'Position',[0 0.25 1 0.75],...
            'Scrollable','off',...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));

% CONSTRUCT CUSTOM CLASS OBJECTS
% Make video alignment information object
alignInfoObj = nigeLab.libs.alignInfo(blockObj,backgroundPanel);

% Make video frame object to track video frames
vidInfoObj = vidInfo(fig,backgroundPanel,vid_F);
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
set(fig,'DeleteFcn',...
   {@deleteFigCB,alignInfoObj,vidInfoObj,graphicsUpdateObj});

% Function for tracking cursor
   function deleteFigCB(~,~,a,v,g)
      delete(a);
      delete(v);
      delete(g);
   end

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