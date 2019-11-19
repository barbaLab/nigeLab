function fig = scoreVideo(varargin)
%% SCOREVIDEO  Locates successful grasps in behavioral video.
%
%  fig = SCOREVIDEO;
%  fig = SCOREVIDEO('NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  varargin       :     (Optional) 'NAME', value input argument pairs.
%
%                       -> 'FNAME_TRIALS' (def: NaN) // Specify as string 
%                                                       to full filename 
%                                                       (including path)
%                                                       of TRIALS file.
%
%                       -> 'FNAME_SCORE' (def: NaN) // Specify as string 
%                                                      to full filename 
%                                                      (including path)
%                                                       of SCORING file.
%
%                       -> 'FNAME_ALIGN' (def: NaN) // Specify as string 
%                                                      to full filename 
%                                                      (including path)
%                                                      of ALIGN file.
%  
% Modifed by: Max Murphy   v3.0  08/07/2018  Basically modified the whole
%                                            thing. Changed to
%                                            object-oriented structure.
%                          v3.1  12/30/2018  Add additional scoring field
%                                            to get the timestamp of
%                                            COMPLETED grasp. Add a bunch
%                                            of documentation. 

%% DEFAULTS
DEF_DIR = 'P:\Extracted_Data_To_Move\Rat\TDTRat'; % Default UI prompt dir
% DEF_DIR = 'C:\RC_Video_Scoring';

VID_DIR = 'C:\RC_Video_Scoring'; % MUST point to where the videos are
VID_TYPE = '.avi';
ALT_VID_DIR = 'K:\Rat\Video\BilateralReach\RC';

% Full filename of any one of these three can be optionally specified
% to skip video scoring selection UI
FNAME_TRIALS = nan;
FNAME_SCORE = nan;
FNAME_ALIGN = nan;

USER = 'MM'; % track scoring
% USER = 'AP';

% NOTE: values for VARS should match HOTKEYS function values!
%  -> Change values in HOTKEYS (at bottom of file), in VARS, and make sure
%     the changes match the table file convention for the '_Scoring.mat'
%     files. In this way it is relatively easy to customize this code to
%     represent whatever kind of scoring you want...

VARS = {'Trial',...
        'Reach',...         % First frame of paw coming through box opening
        'Grasp',...         % First frame of reaching paw closing digits
        'Support',...       % First frame other paw touches glass or apex 
        'Complete',...      % First frame when paw comes back into the box
        'Pellets',...   % # pellets present
        'PelletPresent',... % Is there a pellet in front of the RAT?
        'Stereotyped',... % Is this a stereotyped trial?
        'Outcome',...   % Did the rat carry the pellet into the box?
        'Forelimb'};    % Which handedness is the rat?

% NOTE: values for VAR_TYPE should also match HOTKEYS function values!
%  -> This is the other part to customize the scoring. Different indices of
%     "VAR_TYPE" represent a switch for keeping elements of the GUI
%     straight in terms of what is returned for a given value of that
%     particular variable. The difference between VAR_TYPE [3,4,5] is
%     mostly cosmetic. If you just want to leave things as [0 or 1] for
%     binary events, then just keep VAR_TYPE as [2]. If you try to 
%     customize, and get errors, make sure the VAR_TYPE matches what values
%     is given to that particular variable in the HOTKEYS function at the
%     bottom of this file...

VAR_TYPE = [0,1,1,1,1,2,3,3,4,5]; % must have same number of elements as VARS
                              % options: 
                              % -> 0: Trial "onset" guess
                              % -> 1: Timestamps
                              % -> 2: Counts (0 - 9)
                              % -> 3: No (0) or Yes (1)
                              % -> 4: Unsuccessful (0) or Successful (1)
                              % -> 5: Left (0) or Right (1)
                              
ALIGN_ID = '_VideoAlignment.mat'; % Identifier for file containing 
                                  % VideoStart scalar, which is in seconds,
                                  % of the number of seconds prior to the
                                  % video recording that the neural
                                  % recording was started. So if video
                                  % starts first, then this number should
                                  % be negative.
                                  
TRIAL_ID = '_Trials.mat'; % Identifier for file containing guesses of trial
                          % onset times. Not necessary to have this to
                          % actually run the code. Left-over from some
                          % deprecated stuff and trying to make good
                          % guesses based on DeepLabCut of when the paw is
                          % actually present.
                          
SCORE_ID = '_Scoring.mat'; % Identifier for file that contains 
                           % behaviorData, which is a Matlab Table
                           % variable.
                           % behaviorData.Properties.VariableNames should
                           % be the same as VARS.
                           % behaviorData.Properties.UserData should be the
                           % same as VAR_TYPE.
                           % Number of rows in behaviorData determines how
                           % many maximum possible behavioral trials there
                           % can be scored.

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET TRIALS FILE
if isnan(FNAME_TRIALS)
   if isnan(FNAME_SCORE)
      if isnan(FNAME_ALIGN)
         fOpts = {['*' TRIAL_ID]; ...
                  ['*' SCORE_ID]; ...
                  ['*' ALIGN_ID]};
               
         [FNAME_TRIALS,DIR,fIdx] = uigetfile(fOpts,...
            'Select TRIALS or SCORE or ALIGN file',...
            DEF_DIR);
         if FNAME_TRIALS == 0
            error('No file selected. Script aborted.');
         else
            switch fIdx
               case 1 % TRIAL_ID
                  % leave as is
               case 2 % SCORE_ID
                  FNAME_TRIALS = strrep(FNAME_TRIALS,SCORE_ID,TRIAL_ID);
               case 3 % ALIGN_ID
                  FNAME_TRIALS = strrep(FNAME_TRIALS,ALIGN_ID,TRIAL_ID);
            end
         end
         Name = strsplit(FNAME_TRIALS,TRIAL_ID);
         Name = Name{1};
      else
         [DIR,FNAME_ALIGN,ext] = fileparts(FNAME_ALIGN);
         FNAME_ALIGN = [FNAME_ALIGN,ext];
         Name = strsplit(FNAME_ALIGN,ALIGN_ID);
         Name = Name{1};
      end
   else
      [DIR,FNAME_SCORE,ext] = fileparts(FNAME_SCORE);
      FNAME_SCORE = [FNAME_SCORE,ext];
      Name = strsplit(FNAME_SCORE,SCORE_ID);
      Name = Name{1};
   end
else
   [DIR,FNAME_TRIALS,ext] = fileparts(FNAME_TRIALS);
   FNAME_TRIALS = [FNAME_TRIALS,ext];
   Name = strsplit(FNAME_TRIALS,TRIAL_ID);
   Name = Name{1};
end

%% PARSE VIDEO FILES / LOCATION
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


%% MAKE UI WINDOW AND DISPLAY CONTAINER
fig=figure('Name','Bilateral Reach Scoring',...
           'NumberTitle','off',...
           'Color','k',...
           'Units','Normalized',...
           'MenuBar','none',...
           'ToolBar','none',...
           'Position',[0.1 0.1 0.8 0.8],...
           'UserData','Check');
        
% Panel for displaying information text
dispPanel = uipanel(fig,'Units','Normalized',...
   'BackgroundColor','k',...
   'Position',[0 0 0.75 1]);

        
%% CREATE BEHAVIOR INFORMATION OBJECT

% All potential datapoints
F = struct('vectors',struct(...
      'Trials',struct('folder',DIR,'name',[Name TRIAL_ID])),...
   'scalars',struct(...
      'VideoStart',struct('folder',DIR,'name',[Name ALIGN_ID])),...
   'tables',struct(...
      'behaviorData',struct('folder',DIR,'name',[Name SCORE_ID])));

behaviorInfoObj = behaviorInfo(fig,F,VARS,VAR_TYPE);


%% LOAD VIDEO DATA


% Make custom classes for tracking video and behavioral data
vidInfoObj = vidInfo(fig,dispPanel,vid_F);
 
%% BUILD GRAPHICAL ELEMENTS                   
graphicsUpdateObj = graphicsUpdater(vid_F,VARS);

% Construct video selection interface and load video
vidInfoObj.buildVidSelectionList;

graphics = getGraphics(vidInfoObj);
graphicsUpdateObj.addGraphics(graphics);
graphics = getGraphics(behaviorInfoObj);
graphicsUpdateObj.addGraphics(graphics);


graphicsUpdateObj.addListeners(vidInfoObj,behaviorInfoObj);
                     
% Initialize hotkeys for navigating through movie
set(fig,'WindowKeyPressFcn',...
   {@hotKey,vidInfoObj,behaviorInfoObj});

% Create close request function for figure
set(fig,'CloseRequestFcn',@closeUI);

% Update everything to make sure it looks correct
vidInfoObj.setOffset(behaviorInfoObj.VideoStart);
notify(vidInfoObj,'vidChanged');
behaviorInfoObj.setTrial(nan,behaviorInfoObj.cur,true);
behaviorInfoObj.setUserID(USER);

% % For debugging:
% behaviorData = behaviorInfoObj.behaviorData;
% mtb(behaviorData);

%% Function to set frame when a key is pressed
    function setCurrentFrame(v,newFrame)
       v.setFrame(newFrame);       
    end

%% Function to change button push
   function setCurrentTrial(b,newTrial)
      b.setTrial(nan,newTrial);
   end 

%% General function to update a behaviorData variable
   function setValue(b,varName,val)
      b.setValue(b.getVarIdx(varName),val);
   end

%% General function to update ALL rows of a behaviorData variable
   function setAllValues(b,varName,val)
      b.setValueAll(b.getVarIdx(varName),val);
   end

%% Function to save file
   function saveFile(b)
      b.saveScoring;
   end

%% Function to close figure
   function closeUI(src,~)
      switch src.UserData
         case 'Check' % Prompt user to close
            str = questdlg('Close scoring UI?','Exit','Yes','No','Yes');
            switch str
               case 'Yes'
                  delete(src);
               case 'No'
                  return;
            end
         case 'Force' % Automatically delete without checking
            delete(src);
         otherwise
            return;
      end
   end

%% Function for hotkeys
   function hotKey(~,evt,v,b)
      t = v.tVid;
      switch evt.Key
         case 'comma' % not a stereotyped trial (default)
            setValue(b,'Stereotyped',0);
            
         case 'period' % set as stereotyped trial
            setValue(b,'Stereotyped',1);
            
         case 't' % set reach frame
            setValue(b,'Reach',t);
            
         case 'r' % set no reach for trial
            setValue(b,'Reach',inf);
            
         case 'g' % set grasp frame
            setValue(b,'Grasp',t);
            
         case 'f' % set no grasp for trial
            setValue(b,'Grasp',inf);
            
         case 'b' % set "both" (support) frame
            setValue(b,'Support',t);
            
         case 'v' % (next to 'b') -> no "support" for this trial
            setValue(b,'Support',inf);
            
         case 'multiply' % set trial Complete frame
            setValue(b,'Complete',t); 
            
         case 'divide' % set "no" trial Complete frame (i.e. he never 
                       % brought paw back into box before reaching on next
                       % trial)
            setValue(b,'Complete',inf);
            
         case 'w' % set outcome as Successful
            setValue(b,'Outcome',1);
            
         case 'x' % set outcome as Unsuccessful
            setValue(b,'Outcome',0);
            
         case 'e' % set forelimb as 'Right' (1)
            if strcmpi(evt.Modifier,'alt') % alt + e: all trials are 'right'
               setAllValues(b,'Forelimb',1);
            else
               setValue(b,'Forelimb',1);
            end
            
         case 'q' % set forelimb as 'Left' (0)
            if strcmpi(evt.Modifier,'alt') % alt + q: all trials are 'left'
              setAllValues(b,'Forelimb',0);
            else
               setValue(b,'Forelimb',0);
            end
            
         case 'a' % previous frame
            setCurrentFrame(v,v.frame-1);
            
         case 'leftarrow' % previous trial
            setCurrentTrial(b,b.cur-1);
            
         case 'd' % next frame
            setCurrentFrame(v,v.frame+1);
            
         case 'rightarrow' % next trial
            setCurrentTrial(b,b.cur+1);
            
         case 's' % alt + s = save
            if strcmpi(evt.Modifier,'alt')
               saveFile(b);
            end           
            
         case 'numpad0'
            setValue(b,'Pellets',0);
         case 'numpad1'
            setValue(b,'Pellets',1);
         case 'numpad2'
            setValue(b,'Pellets',2);
         case 'numpad3'
            setValue(b,'Pellets',3);
         case 'numpad4'
            setValue(b,'Pellets',4);
         case 'numpad5'
            setValue(b,'Pellets',5);
         case 'numpad6'
            setValue(b,'Pellets',6);
         case 'numpad7'
            setValue(b,'Pellets',7);
         case 'numpad8'
            setValue(b,'Pellets',8);
         case 'numpad9'
            setValue(b,'Pellets',9);     
         case 'subtract'
            setValue(b,'PelletPresent',0);
         case 'add'
            setValue(b,'PelletPresent',1);
            
         case 'escape' % Close scoring UI
            closeUI(gcf);

         case 'delete'
            b.removeTrial;
            
         case 'space'
            v.playPauseVid;
      end
   end

end