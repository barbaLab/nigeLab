function fig = scoreVideo(blockObj)
%SCOREVIDEO  Locates successful grasps in behavioral video.
%
%  fig = blockObj.SCOREVIDEO;
%
%  Returns fig, a graphics object handle to the figure that contains the
%     video panel, controller panel, and associated information panels.

if ~blockObj.Pars.Video.HasVideo
   fig = [];
   [fmt,idt,type] = getDescriptiveFormatting(blockObj);
   dbstack();
   nigeLab.utils.cprintf('Errors*','%s[SCOREVIDEO]: ',idt);
   nigeLab.utils.cprintf(fmt(1:(end-1)),...
      '%s %s parameters indicate that it has no video(s)\n',...
      type,blockObj.Name);
   if nargout < 1
      clear fig
   end
   return;
end
checkCompatibility(blockObj,{blockObj.ScoringField,'Video'});

%MAKE UI WINDOW AND DISPLAY CONTAINER
fig=figure('Name','Behavior Scoring',...
   'NumberTitle','off',...
   'Color',nigeLab.defaults.nigelColors('background'),...
   'Units','Normalized',...
   'MenuBar','none',...
   'ToolBar','none',...
   'Position',[0.1 0.1 0.8 0.8],...
   'BusyAction','cancel',...
   'UserData',...
   struct(...
   'KeyPressFcn',blockObj.Pars.Video.ScoringHotkeyFcn,...
   'KeyPressHelpFcn',blockObj.Pars.Video.ScoringHotkeyHelpFcn...
   )...
   );

% Panel for displaying video
dispPanel = nigeLab.libs.nigelPanel(fig,...
   'Units','Normalized',...
   'String','Pellet Retrieval Scoring Interface',...
   'TitleFontSize',16,...
   'Position',[0 0 0.75 1]);

% Panel for displaying heads up information
infoPanel = nigeLab.libs.nigelPanel(fig,...
   'Units','Normalized',...
   'String','Info',...
   'TitleFontSize',22,...
   'Position',[0.765 0 0.235 1]);

%Create objects that track event-related and video-related info
v = nigeLab.libs.VidGraphics(blockObj,dispPanel);
b = nigeLab.libs.behaviorInfo(blockObj,infoPanel,v); % "Event"

%Assign figure interaction functions
set(fig,'WindowKeyPressFcn',{@hotKey,v,b});
set(fig,'CloseRequestFcn',{@closeUI,b,v});

%Print instructions to command window to help user
if blockObj.Verbose
   nigeLab.utils.cprintf('Comments','\n-->\tPress ');
   nigeLab.utils.cprintf('Keywords','''h''');
   nigeLab.utils.cprintf('Comments',' for list of scoring commands. <--\n');

   nigeLab.utils.cprintf('Comments','\n-->\t(Or) press ');
   nigeLab.utils.cprintf('Keywords','''control + [key]''');
   nigeLab.utils.cprintf('Comments',' for specific help. <--\n');
end

%Helper functions
% Closes the current user-interface (UI)
   function closeUI(src,~,behaviorInfoObj,vidGraphicsObj)
      % CLOSEUI  Prompts to see if user really wants to close window
      str = questdlg('Close scoring UI?','Exit','Yes','No','Yes');
      if strcmp(str,'Yes')
         % Update close request function to default
         set(src,'CloseRequestFcn','closereq');
         % Delete behavior-info object
         delete(behaviorInfoObj);
         delete(vidGraphicsObj);
      end
   end

% Triggered on keypress while figure is in-focus
   function hotKey(src,evt,vidGraphicsObj,behaviorInfoObj)
      % HOTKEY  Function cases for different keyboard inputs
      %
      %  fig.WindowKeyPressFcn = {@hotKey,vidInfoObj,behaviorInfoObj};
      %
      %  hotkey(src,evt,v,b):
      %     src -- Source object (figure for scoring UI)
      %     evt -- Keypress eventdata, which has evt.Key for the name of
      %              the key pressed and evt.Modifier for any other key,
      %              such as 'alt' or 'ctrl' that was pressed concurrently.
      %     v -- nigeLab.libs.vidInfo class object that tracks video frame
      %           timing and offset info, etc.
      %     b -- nigeLab.libs.behaviorInfo class object that tracks event
      %           data from scoring etc.
      
      if isempty(evt.Modifier)
         src.UserData.KeyPressFcn(evt,vidGraphicsObj,behaviorInfoObj);
         switch evt.Key
            case 'escape' % Close scoring UI
               close(src);
            case 'h'
               src.UserData.KeyPressHelpFcn();
         end
      elseif strcmpi(evt.Modifier,'Control')
         if strcmpi(evt.Modifier,evt.Key)
            return;
         end
         if ~iscell(evt.Key)
            key_help = {evt.Key};
         else
            key_help = evt.Key;
         end
         src.UserData.KeyPressHelpFcn(key_help);
      else
         src.UserData.KeyPressFcn(evt,vidGraphicsObj,behaviorInfoObj);
      end
   end

end