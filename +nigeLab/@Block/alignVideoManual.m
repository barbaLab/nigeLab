function fig = alignVideoManual(blockObj,digStreamInfo,vidStreamInfo)
%ALIGNVIDEOMANUAL  Manually obtain offset between video and neural record,
%                    using specific streams from the digital record that
%                    are overlayed on top of streams parsed from the video
%                    record.
%
%  blockObj.alignVideoManual();
%  blockObj.alignVideoManual(digStreamName);
%  blockObj.alignVideoManual(digStreamName,vidStreamInfo);
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
%  vidStreamInfo  :  Same as digStreamInfo, but for a single vidStream of
%                    interest (optional).
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

% Parse inputs
if nargin < 3
   vidStreamInfo = [];
end

if nargin < 2
   digStreamInfo = [];
end

% Get the info for digital and video streams to synchronize
digStreamInfo = getDigStreamInfo(blockObj,digStreamInfo);
vidStreamInfo = getVidStreamInfo(blockObj,vidStreamInfo);

% Assign stream info to blockObj so it is passed to alignInfo object
blockObj.UserData = struct(...
   'digStreamInfo',digStreamInfo,...
   'vidStreamInfo',vidStreamInfo);

% Build graphics
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
            'String','Stream Alignment',...
            'Tag','alignPanel',...
            'Units','normalized',...
            'Position',[0 0 1 0.25],...
            'Scrollable','off',... % could add this at some point
            'TitleStringX',0.1,...
            'TitleAlignment','left',...
            'PanelColor',nigeLab.defaults.nigelColors('w'),...
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

% Function for selecting digital streams to use
   function digStreamInfo = getDigStreamInfo(blockObj,d)
      % GETDIGSTREAMINFO  Returns structs with info for the digital streams 
      %                   to use in the alignment interface.
      %
      %  digStreamInfo = getDigStreamInfo(blockObj,d);
      
      % Parse digStreamInfo input
      if ~isempty(d)
         digStreamInfo = d;
         return;
      end
      
      % Make dropdown radio box
      [title_str,prompt_str,opts] = ...
         nigeLab.utils.getDropDownRadioStreams(blockObj);
      str = 'Yes';
      d = struct('name',[],'field',[],'idx',[]);
      k = 0;
      % Allow user to select multiple streams
      while strcmp(str,'Yes')
         k = k + 1;
         [d(k).name,d(k).field,d(k).idx] = ...
            nigeLab.utils.uidropdownradiobox(...
               title_str,...
               prompt_str,...
               opts,...
               false);
         if isnan(d(k).idx(1))
            break;
         end
         opts{d(k).idx(1,1),1} = setdiff(opts{d(k).idx(1,1),1},...
            d(k).name);
         if isempty(opts{d(k).idx(1,1),1})
            break;
         end
         % Second dropdownbox (simple) allows you to keep adding streams
         str = nigeLab.utils.uidropdownbox({'Selection Option Window';...
            'Select More Streams?'},...
            {'Add More Digital Streams?';'(Synchronized)'},{'No','Yes'},...
            false);

      end
      digStreamInfo = d;
   end

% Function for selecting video streams to use
   function vidStreamInfo = getVidStreamInfo(blockObj,v)
      % GETVIDSTREAMINFO  Returns structs with info for the video streams
      %                   to use
      %
      %  vidStreamInfo = getVidStreamInfo(blockObj,v);

      if ~isempty(v)
         vidStreamInfo = v;
         return;
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
      vStrName = nigeLab.utils.uidropdownbox('Select Vid Stream',...
         {'Video Stream to Use';'(Non-Synchronized)'},opts);
      % Subtract 1 from strIdx to account for 'none' being added
      strIdx = find(ismember(opts,vStrName),1,'first')-1;
      if strIdx == 0
         vidStreamInfo = [];
      end
      
      vidStreamInfo = struct;
      vidStreamInfo.name = opts{strIdx+1};
      vidStreamInfo.idx = strIdx;

   end

% Function for hotkeys
   function hotKey(src,evt,v,a)
      switch evt.Key     
         case 's' % Press 'alt' and 's' at the same time to save
            if strcmpi(evt.Modifier,'alt')
               saveAlignment(a);
            end
            
         case 'a' % Press 'a' to go back one frame
            advanceFrame(v,-1);
            
         case 'leftarrow' % Press 'leftarrow' key to go back 5 frames
            advanceFrame(v,-5);
            
         case 'd' % Press 'd' to go forward one frame
            advanceFrame(v,1);
            
         case 'rightarrow' % Press 'rightarrow' key to go forward 5 framse
            advanceFrame(v,5);
            
         case  'subtract' % Press numpad '-' key to zoom out on time series
            zoomOut(a);
            
         case 'add' % Press numpad '+' key to zoom in on time series
            zoomIn(a);
            
         case 'space' % Press 'spacebar' key to play or pause video
            v.playPauseVid;
            
         case 'escape'
            close(src);
      end
   end
end