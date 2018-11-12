function VidName = VidKinematics(varargin)
%% VIDKINEMATICS Get the pseudokinematics of single-plane rat reaches.
%
%   VidName = VIDKINEMATICS('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs.
%                   NAME strings correspond to variables listed in the
%                   DEFAULTS section of the code.
%
%                   -> 'IDIR', (default: Videos location). Pathway where UI
%                                        for file selection defaults. If
%                                        FNAME is specified, this is where
%                                        FNAME will be searched for.
%
%                   -> 'FNAME', (default: does not exist; force user to use
%                                         file selection UI). Can be
%                                         specified as the name of the
%                                         file, located in IDIR.
%   --------
%    OUTPUT
%   --------
%    VidName    :   (string) Name of video that was just detected.
%
%   Saves a file with the reach kinematics in the plane of the video
%   recording, as well as some indicators of the rat posture during each
%   reach snippet.
%
% By: Max Murphy    v1.0    02/10/2017  Original version (R2016b)

%% DEFAULTS
clc; clearvars -except varargin
IDIR = 'C:\Users\Max Murphy\CloudStation\Max Murphy\Matlab Scripts\161227 RC Data Full Recordings\Data\Videos\';
BDIR = 'C:\Users\Max Murphy\CloudStation\Max Murphy\Matlab Scripts\161227 RC Data Full Recordings\Data\Scored Behavior Files\';
B_ID = '_VideoScoredSuccesses.mat';
SDIR = 'C:\Users\Max Murphy\CloudStation\Max Murphy\Matlab Scripts\161227 RC Data Full Recordings\Data\Kinematics\';
S_ID = '_Kinematics.mat';
SVID = '_ReducedVideo.mat';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    evaluate([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% LOAD VIDEO AND BEHAVIORAL SCORING
if exist('FNAME','var')==0
    [FNAME,IDIR,~] = uigetfile('R*.avi', 'Select video', IDIR);
    if FNAME == 0
        error('No file selection, script aborted.');
    end
    NAME = FNAME(1:end-4);
    BNAME = [NAME B_ID];
    
    if exist([BDIR BNAME],'file')==0
        error('Associated behavior file for video not found.');
    end
    
else
    if exist([IDIR FNAME],'file')==0
        error('Specified file does not exist.');
    end
    NAME = FNAME(1:end-4);
    BNAME = [NAME B_ID];
    
    if exist([BDIR BNAME],'file')==0
        error('Associated behavior file for video not found.');
    end
    
end
load([BDIR BNAME], 'VideoStart', 'VideoEnd', ...
                   'VideoLength', 'DataLength', ...
                   'BeamBreaks', 'PelletBreaks', ...
                   'TotalSamples', 'SamplingFrequency', ...
                   'Reaches', 'Grasps', ...
                   'SuccessfulGrasp', 'BothArms');
Starts = []; Stops = []; 
StartStem = stem(Starts,ones(size(Starts)),'-g*');
StopStem = stem(Stops,ones(size(Stops)),'-rx');
Vid = VideoReader([IDIR FNAME]);

%% EXTRACT PARAMETERS
FPS=Vid.FrameRate;
NumFrames=Vid.NumberofFrames;
TimerPeriod=2*round(1000/FPS)/1000;
LegendTxt=cell(0,0);  

%% CONSTRUCT FIGURE
fid=figure('Visible', 'on', ...
           'Selected', 'on', ...
           'Name', 'Kinematic Selection Tool');


% Stem plot for event navigation
ax1=subplot(5,1,[1:2]);hold on;

if ~isempty(BeamBreaks)
    stem(BeamBreaks,ones(size(BeamBreaks)),'b');
    LegendTxt{length(LegendTxt)+1}='Beam Break';
end
if ~isempty(PelletBreaks)
    stem(PelletBreaks,ones(size(PelletBreaks)),'m');
    LegendTxt{length(LegendTxt)+1}='Pellet Break';
end
if ~isempty(Reaches)
    ReachStem=stem(Reaches,ones(size(Reaches)),':*g');
    LegendTxt{length(LegendTxt)+1}='Reach';
end
if ~isempty(Grasps)
    GraspStem=stem(Grasps,ones(size(Grasps)),':xc');
    LegendTxt{length(LegendTxt)+1}='Grasp';
end
if ~isempty(SuccessfulGrasp)
    SuccessStem=stem(SuccessfulGrasp,ones(size(SuccessfulGrasp)),'-.+y');
    LegendTxt{length(LegendTxt)+1}='Success';
end
axis([0 DataLength 0 1]);
CurNeuralLoc=line([VideoStart VideoStart],[0 1],'Color','k','LineStyle','--','LineWidth',2);
LegendTxt{length(LegendTxt)+1}='Current Position';
legend(LegendTxt)
set(ax1,'ButtonDownFcn',@SkipToPoint);


% Video plot
ax2=subplot(5,1,[3:5]);
BitsPerPixel = Vid.BitsPerPixel;
VidHeight = Vid.Height;
VidFormat = Vid.VideoFormat;
VidWidth = Vid.Width;

f=Vid.read(1); % reading first frame of the video

imshow(f); % showing the first frame of the video


% Annotate graphs (video timer, name)
VidTimeDisp=annotation('textbox',[0.1 0.55 0.175 0.02],...
                       'Units', 'Normalized', ...
                       'Position', [0.1 0.55 0.175 0.02], ...
                       'String',num2str(0.00,'Video Time: %0.2f'));

PlotName = strrep(NAME, '_', ' ');

NeuralTimeDisp = annotation('textbox',[0.1 0.95 0.3 0.02],...
                       'Units', 'Normalized', ...
                       'Position', [0.1 0.95 0.3 0.02], ...
                       'String', num2str(VideoStart, [PlotName 'Neural Time: %0.2f']));

%timer to play video
play_timer = timer('TimerFcn',@play_timer_callback,...
                   'ExecutionMode','fixedRate');

set(gcf, 'Units', 'Normalized', ...
         'Position',[0.33 0.1 0.33 0.8]);

val=1; % Initially position is the first frame
% Slider function that will display the full current position within the
% video
sld=uicontrol('Style', 'slider',...
    'Min',1,'Max',NumFrames,'Value',val,...
    'Units', 'normalized', ...
    'Position', [0.1 0.15 0.833 0.02],...
    'BackgroundColor', 'k', ...
    'ForegroundColor', 'w', ...
    'Callback', @SetFrame,...
    'SliderStep',[1/NumFrames 100/NumFrames]);

% Start/Stop pushbutton for video play
StartStopButton=uicontrol('Style', 'pushbutton', ...
    'String', 'Play/Pause',...
    'Units', 'Normalized', ...
    'Position', [0.1 0.1 0.1 0.033],...
    'Callback', @StartStopPush);

% Pushbutton to save 
uicontrol('Style', 'pushbutton', 'String', ...
    'Save Behavior',...
    'Units', 'Normalized', ...
    'Position', [0.1 0.028 0.1 0.033],...
    'Callback', @SavePush);

% Pushbutton to add/remove Start Training Time
uicontrol('Style', 'pushbutton', ...
    'String', '+/- Start',...
    'Units', 'Normalized', ...
    'Position', [0.22 0.028 0.1 0.050],...
    'BackgroundColor', [0 0.7 0], ...
    'ForegroundColor', 'k', ...
    'Callback', @AddRemoveStart);

% Pushbutton to move current position to the Start Event
uicontrol('Style', 'pushbutton', 'String', 'GoTo Start',...
    'Units', 'Normalized', ...
    'Position', [0.34 0.028 0.1 0.050],...
    'BackgroundColor', [0 1 0], ...
    'ForegroundColor', 'k', ...
    'Callback', @GoToStart);

% Pushbutton to add/remove Stop Training Time
uicontrol('Style', 'pushbutton', ...
    'String', '+/- Stop',...
    'Units', 'Normalized', ...
    'Position', [0.46 0.028 0.1 0.050],...
    'BackgroundColor', [0.7 0 0], ...
    'ForegroundColor', 'w', ...
    'Callback', @AddRemoveStop);

% Pushbutton to move current position to the Stop Event
uicontrol('Style', 'pushbutton', 'String', 'GoTo Stop',...
    'Units', 'Normalized', ...
    'Position', [0.58 0.028 0.1 0.050],...
    'BackgroundColor', [1 0 0], ...
    'ForegroundColor', 'w', ...
    'Callback', @GoToStop);

% Pushbutton to create video bounding box
uicontrol('Style', 'pushbutton', ...
    'String', 'Set Bounds',...
    'Units', 'Normalized', ...
    'Position', [0.22 0.0830 0.22 0.050],...
    'BackgroundColor', [0.5 0.5 1], ...
    'ForegroundColor', 'k', ...
    'Callback', @SetBoundBox);

% Pushbutton to save video bounding box
uicontrol('Style', 'pushbutton', ...
    'String', 'Confirm Bounds',...
    'Units', 'Normalized', ...
    'Position', [0.46 0.0830 0.22 0.050],...
    'BackgroundColor', 'b', ...
    'ForegroundColor', 'w', ...
    'Callback', @SaveBoundBox);

% Pushbutton to zoom out (reset) on neural data at current point.
uicontrol('Style', 'pushbutton', 'String', '-',...
    'Units', 'Normalized', ...
    'Position', [0.1 0.064 0.049 0.033],...
    'Callback', @ZoomResetPush);

% Pushbutton to zoom in on neural data at current point.
uicontrol('Style', 'pushbutton', 'String', '+',...
    'Units', 'Normalized', ...
    'Position', [0.151 0.064 0.049 0.033],...
    'Callback', @ZoomInPush);

% Pushbutton to export reduced-size video
ExpPush = uicontrol('Style', 'pushbutton', ...
                    'String', 'Export Image',...
                    'Units', 'Normalized', ...
                    'Position', [0.7 0.028 0.23 0.1050],...
                    'BackgroundColor', [0.94 0.94 0.94], ...
                    'ForegroundColor', 'w', ...
                    'Enable', 'off', ...
                    'Callback', @ExportVideo);

bbox = imrect(ax2);
BoundingBox = getPosition(bbox);
BoundingBox = [floor(BoundingBox(1)) ...
               floor(BoundingBox(2)) ...
               ceil(BoundingBox(3))  ...
               ceil(BoundingBox(4))];
           
%% Function to set frame when slider is moved
    function SetFrame(source, ~)
        RestartTimer=0;
        % if the timer is currently running, we need to stop it to move the
        % slider and then restart it later
        if strcmp(get(play_timer,'Running'), 'on')
            stop(play_timer);
            RestartTimer=1;
        end
        
        val = source.Value; % read the slider value
        val = round(val);

        f=Vid.read(round(val)); % read the chosen video frame
        axes(ax2); imshow(f); % show the chosen video frame
        set(CurNeuralLoc,'XData',[VideoStart+round(val)/FPS VideoStart+round(val)/FPS]); % set the slider in the behavior plot
        set(VidTimeDisp,'String',num2str(val/FPS,'Video Time: %0.2f')); % set the numeric time display next to the video
        set(NeuralTimeDisp, 'String', num2str(round(val)/FPS + VideoStart, [PlotName 'Neural Time: %0.2f']));
        
        if RestartTimer==1
            set(play_timer, 'Period', TimerPeriod);
            start(play_timer);
        end
    end

%% Function to toggle between starting and stopping the video playback
    function StartStopPush(~,~)
        if strcmp(get(play_timer,'Running'), 'off') % if the video is not running, we want to start the timer to turn it on
            set(StartStopButton,'String','Stop'); % resetting button
            set(play_timer, 'Period', TimerPeriod);
            start(play_timer); % starting timer
        else % if the video is currently running we want to stop it
            stop(play_timer); % stopping timer
            set(StartStopButton,'String','Play'); % resetting button
        end
    end


%% Function to advance the video automatically when play is selected
    function play_timer_callback(src, ~) 
        %executed at each timer period, when playing the video
        if round(val) < NumFrames % if we are not at the end, advance on frame
            val=val+1;
            val=round(val);
            
            f=Vid.read(round(val)); % read next video frame
            axes(ax2);
            imshow(f); % display video frame
            set(CurNeuralLoc,'XData',[VideoStart+round(val)/FPS VideoStart+round(val)/FPS]); %reset position marker in behavior plot
            set(sld,'Value',val); %reset slider position
            set(VidTimeDisp,'String',num2str(val/FPS,'%0.2f')); %reset clock
            set(NeuralTimeDisp, 'String', num2str(round(val)/FPS + VideoStart, [PlotName 'Neural Time: %0.2f']));
            curPosition = get(CurNeuralLoc, 'XData');
            curPosition = curPosition(1);
            set(ax1, 'XLim', [curPosition - 0.6 curPosition + 0.6]) 
        elseif strcmp(get(play_timer,'Running'), 'on'),
            stop(play_timer);  %stop the timer if the end is reached
            set(StartStopButton,'String','Play'); %reset push button
        end
    end

%% Function to skip to point clicked in neural data
    function SkipToPoint(src, ~)
        newPosition = src.CurrentPoint(1,1);
        val=round((newPosition-VideoStart)*FPS);

        f=Vid.read(round(val)); % read next video frame
        axes(ax2);
        imshow(f); % display video frame

        set(CurNeuralLoc,'XData',[newPosition newPosition]);
        set(VidTimeDisp,'String',num2str(val/FPS,'Video Time: %0.2f')); % set the numeric time display next to the video
        set(NeuralTimeDisp, 'String', num2str(round(val)/FPS + VideoStart, [PlotName 'Neural Time: %0.2f']));
        set(sld,'Value',val); %reset slider position
    end

%% Function to Add or Remove a Start Event at the Current Location
    function AddRemoveStart(~,~)
        curPosition=get(CurNeuralLoc,'XData');
        curPosition=curPosition(1);
        if isempty(Starts) 
            % If there are no current reaches we want to add this location and plot the reach locations
            Starts = curPosition
            axes(ax1);StartStem=stem(Starts,ones(size(Starts)),'-*g');
            LegendTxt{length(LegendTxt)+1}='Start';
            legend(LegendTxt);
        else
            ind=find(abs(curPosition-Starts)<eps);
            if isempty(ind)
                % If our current position is not a reach, we'd like to add the current position to the reaches it
                if isempty(Stops)
                    Starts = curPosition
                else
                    if curPosition >= Stops
                        disp('Invalid position. Start must be before Stop');
                    else
                        Starts = curPosition
                    end
                end
            else
                % Otherwise our current position is already in reaches and we should remove it
                Starts = []
            end
            % Update the reaches stem
            set(StartStem,'XData',Starts);set(StartStem,'YData',ones(size(Starts)));
            % If Starts is now empty, we should remove it and the legend
            % entry and redraw the legend
            if isempty(Starts)
                axes(ax1);
                for i=1:length(LegendTxt)
                    if(strcmp(LegendTxt{i},'Start'))
                        LegendTxt(i)=[];
                        legend(LegendTxt);
                        break
                    end
                end
            end
        end
    end

%% Function to Add or Remove a Stop Event at the Current Location
    function AddRemoveStop(~,~)
        curPosition=get(CurNeuralLoc,'XData');
        curPosition=curPosition(1);
        if isempty(Stops) 
            % If there are no current reaches we want to add this location and plot the reach locations
            Stops=curPosition
            axes(ax1);
            StopStem=stem(Stops,ones(size(Stops)),'-xr');
            LegendTxt{length(LegendTxt)+1}='Stop';
            legend(LegendTxt);
        else
            ind=find(abs(curPosition-Stops)<eps);
            if isempty(ind)
                % If our current position is not a reach, we'd like to add the current position to the reaches it
                if isempty(Starts)
                    Stops=curPosition
                else
                    if curPosition <= Starts
                        disp('Invalid position. Stop must be after Start.');
                    else
                        Stops = curPosition
                    end
                end
            else
                % Otherwise our current position is already in reaches and we should remove it
                Stops(ind)=[]
            end
            % Update the reaches stem
            set(StopStem,'XData',Stops);set(StopStem,'YData',ones(size(Stops)));
            % If Starts is now empty, we should remove it and the legend
            % entry and redraw the legend
            if isempty(Stops)
                axes(ax1);
                for i=1:length(LegendTxt)
                    if(strcmp(LegendTxt{i},'Stop'))
                        LegendTxt(i)=[];
                        legend(LegendTxt);
                        break
                    end
                end
            end
        end
    end

%% Function to Navigate to Start Event
    function GoToStart(~,~)
        if ~isempty(Starts)           
            newPosition = Starts;
            val=round((newPosition-VideoStart)*FPS);

            f=Vid.read(round(val)); % read next video frame
            axes(ax2);
            imshow(f); % display video frame
            
            set(CurNeuralLoc,'XData',[newPosition newPosition]);
            set(VidTimeDisp,'String',num2str(val/FPS,'Video Time: %0.2f')); % set the numeric time display next to the video
            set(NeuralTimeDisp, 'String', num2str(round(val)/FPS + VideoStart, [PlotName 'Neural Time: %0.2f']));
            set(sld,'Value',val); %reset slider position
            %Zoom in on current position
            set(ax1, 'XLim', [newPosition - 0.6 newPosition + 0.6]) 
        end
    end

%% Function to Navigate to a Stop Event
    function GoToStop(~,~)
        if ~isempty(Stops)
            newPosition=Stops;
            if isempty(newPosition)
                return
            end
            val=round((newPosition-VideoStart)*FPS);

            f=Vid.read(round(val)); % read next video frame
            axes(ax2);
            imshow(f); % display video frame
            
            set(CurNeuralLoc,'XData',[newPosition newPosition]);
            set(VidTimeDisp,'String',num2str(val/FPS,'Video Time: %0.2f')); % set the numeric time display next to the video
            set(NeuralTimeDisp, 'String', num2str(round(val)/FPS + VideoStart, [PlotName 'Neural Time: %0.2f']));
            set(sld,'Value',val); %reset slider position
            %Zoom in on current position
            set(ax1, 'XLim', [newPosition - 0.6 newPosition + 0.6]) 
        end
    end

%% Function to create bounded ROI for reducing file sizes
    function SetBoundBox(~,~)
        delete(bbox);
        bbox = imrect(ax2);
    end

%% Function to save bounded ROI
    function SaveBoundBox(~,~)
        BoundingBox = getPosition(bbox);
        BoundingBox = [floor(BoundingBox(1)) ...
                       floor(BoundingBox(2)) ...
                       ceil(BoundingBox(3))  ...
                       ceil(BoundingBox(4))];
    end

%% Function to zoom out (reset) on neural data
    function ZoomResetPush(~,~)
        %Reset axis limits.
        set(ax1, 'XLim', [0 TotalSamples/SamplingFrequency])
    end

%% Function to zoom in on neural data
    function ZoomInPush(~,~)
        %Zoom in on current position
        curPosition = get(CurNeuralLoc, 'XData');
        curPosition = curPosition(1);
        set(ax1, 'XLim', [curPosition - 0.6 curPosition + 0.6]) 
    end


%% Function to Save the Bahavior
    function SavePush(~,~)
        savestr=[SDIR NAME S_ID];
        if exist(SDIR, 'dir')==0
            mkdir(SDIR);
        end
        save(savestr,...
            'VideoStart','VideoEnd',...
            'VideoLength','DataLength',...
            'BeamBreaks', 'PelletBreaks', ...
            'TotalSamples', 'SamplingFrequency', ...
            'Reaches', 'Grasps', ...
            'SuccessfulGrasp', ...
            'Starts', 'Stops', 'BoundingBox', ...
            'NumFrames', 'VidHeight', 'VidWidth', ...
            'BitsPerPixel', 'VidFormat','FPS','-v7.3');
        ExpPush.Enable = 'on';
        ExpPush.BackgroundColor = 'k';
    end
    fid.Selected = 'on';

%% Function to export reduced-size video
    function ExportVideo(~,~)
        clc; startTic = tic;
        V = cell(NumFrames,1);
        hw = waitbar(0,'Please wait, converting video...');
        for iF = 1:NumFrames
            I = Vid.read(iF);
            I = I(BoundingBox(2):(BoundingBox(2)+BoundingBox(4)), ...
                                  BoundingBox(1):(BoundingBox(1)+BoundingBox(3)),:);
            V{iF,1} = I; clear I;
            waitbar(iF/NumFrames);
        end
        delete(hw);
        
        disp('Please wait, saving reduced-size video...');
        save([SDIR NAME SVID], 'V', '-v7.3');
        fprintf(1,'\n');
        fprintf(1,'...complete.');
        fprintf(1,'\n');
        ElapsedTime(startTic);
        fprintf(1,'\n');
        fprintf(1,'%s:\n',NAME);
        fprintf(1,'-------------------------------------------\n');
        fprintf(1,'%d pixels (H) x %d pixels (W) x %d frames\n', ...
                        VidHeight,VidWidth,NumFrames); 
        fprintf(1,'\n');
        fprintf(1,'              v v v v v v\n');
        fprintf(1,'\n');
        
        fprintf(1,'%d pixels (H) x %d pixels (W) x %d frames\n', ...
                        BoundingBox(4),BoundingBox(3),NumFrames);
        fprintf(1,'-------------------------------------------\n');
        fprintf(1,'\n');
    end
    VidName = NAME;
end