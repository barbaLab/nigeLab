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
%  digStreamInfo  :  Stream field 'custom_channel_name' 
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
%    fig          :  Figure handle that can be used to block subsequent
%                    execution using waitfor(fig). This is the handle to
%                    the figure that contains all the alignment interface.
%
%  After completing alignVideoManual, the offset between video and neural
%  data will be saved automatically. It is returned as a time in seconds, 
%  where a positive value denotes that the video starts after the neural 
%  record. The value of offset is automatically saved as the 'ts' property 
%  of a special 'Header' file located with the other 'ScoredEvents' files 
%  in the block hierarchy.

%% Parse inputs
if nargin < 3
   vidStreamName = [];
end

if nargin < 2
   digStreamInfo = [];
end

% Parse digStreamName input
if isempty(digStreamInfo)
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
            opts,...
            false);
      if isnan(digInfo(k).idx(1))
         break;
      end
      opts{digInfo(k).idx(1,1),1} = setdiff(opts{digInfo(k).idx(1,1),1},...
         digInfo(k).name);
      if isempty(opts{digInfo(k).idx(1,1),1})
         break;
      end
      str = nigeLab.utils.uidropdownbox({'Selection Option Window';...
         'Select More Streams?'},...
         {'Add More Digital Streams?';'(Synchronized)'},{'No','Yes'},false);
      
   end
end

% Parse vidStreamName input
opts = getName(blockObj.Videos,'vidstreams');
if ~iscell(opts)
   opts = {opts};
end
% 'none' is default response for uidropdownbox; if we don't want to use a
% video stream for alignment, then select 'none' and only drag the digital
% record to match up to the frames of interest (e.g. watch video until
% first LED goes on, then drag LED high signal so that it transitions to
% high for the first time at the same time as the current video time
% marker)
opts = ['none', opts];
if isempty(vidStreamName)
   vidStreamName = nigeLab.utils.uidropdownbox('Select Vid Stream',...
      {'Video Stream to Use';'(Non-Synchronized)'},opts);
end
% Subtract 1 from strIdx to account for 'none' being added
strIdx = find(ismember(opts,vidStreamName),1,'first')-1;

% Assign stream info to blockObj so it is passed to alignInfo object
blockObj.UserData = struct(...
   'digStreams',digInfo,...
   'vidStreams',struct('name',opts{strIdx+1},'idx',strIdx,'vidIdx',1));

%% Build graphics

% Make figure to put everything in
fig=figure('Name','Manual Video Alignment Interface',...
   'Color',nigeLab.defaults.nigelColors('background'),...
   'NumberTitle','off',...
   'MenuBar','none',...
   'ToolBar','none',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.8],...
   'UserData',struct('flag',false,'h',[]));

% Make two panels:
% 1) vidPanel for containing the video and vidInfoObj
%  --> Note: This will "contain" the HUD panel at the top
vidPanel = nigeLab.libs.nigelPanel(fig,...
            'String',strrep(blockObj.Name,'_','\_'),...
            'Tag','vidPanel',...
            'Units','normalized',...
            'Position',[0 0.25 1 0.75],...
            'Scrollable','off',...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
vidInfoObj = nigeLab.libs.vidInfo(blockObj,vidPanel);
         
% 2) infoPanel for containing the alignInfoObj
alignPanel = nigeLab.libs.nigelPanel(fig,...
            'String',strrep(blockObj.Name,'_','\_'),...
            'Tag','alignPanel',...
            'Units','normalized',...
            'Position',[0 0 1 0.25],...
            'Scrollable','off',... % could add this at some point
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
alignInfoObj = nigeLab.libs.alignInfo(blockObj,alignPanel);

% Make listener object to integrate class information
graphicsUpdateObj = nigeLab.libs.graphicsUpdater(blockObj,...
   vidInfoObj,alignInfoObj);

% Add figure interactive functions
set(fig,'KeyPressFcn',{@hotKey,vidInfoObj,alignInfoObj});
set(fig,'DeleteFcn',{@deleteFigCB,alignInfoObj,vidInfoObj,graphicsUpdateObj});

% Function for tracking cursor
   function deleteFigCB(~,~,a,v,g)
      % DELETEFIGCB  Ensure that alignInfo, videoInfo, and graphicsUpdater
      %              are all destroyed on Figure destruction.
      
      delete(a);
      delete(v);
      delete(g);
   end

% Function for hotkeys
   function hotKey(src,evt,v,a)
      switch evt.Key     
         case 's' % Press 'alt' and 's' at the same time to save
            if strcmpi(evt.Modifier,'alt')
               a.saveAlignment;
            end
            
         case 'a' % Press 'a' to go back one frame
            v.retreatFrame;
            
         case 'leftarrow' % Press 'leftarrow' key to go back 5 frames
            v.retreatFrame(5);
            
         case 'd' % Press 'd' to go forward one frame
            v.advanceFrame;
            
         case 'rightarrow' % Press 'rightarrow' key to go forward 5 framse
            v.advanceFrame(5);
            
         case  'subtract' % Press numpad '-' key to zoom out on time series
            a.zoomOut;
            
         case 'add' % Press numpad '+' key to zoom in on time series
            a.zoomIn;
            
         case 'space' % Press 'spacebar' key to play or pause video
            v.playPauseVid;
            
         case 'escape'
            close(src);
      end
   end
end