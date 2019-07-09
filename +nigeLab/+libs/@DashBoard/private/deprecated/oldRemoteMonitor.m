function oldRemoteMonitor(obj,Labels,Files,Fig,parent)
%% Init files and bar
if ~iscell(Files),Files = {Files};end
obj.remoteMonitorData = progressbar(obj,parent,obj.remoteMonitorData,Files,Labels);
%set up flags for if button is held down
obj.remoteMonitorData.timerObject = timer('Name','RemoteMonitor',...
    'TimerFcn',{@readFiles,obj,parent},...
    'ExecutionMode','fixedRate',...
    'Period',1);
% readFiles(1,1,obj,parent)          %% debug!
Fig.CloseRequestFcn = {@destroyTimerOnClose,obj.remoteMonitorData.timerObject};
start(obj.remoteMonitorData.timerObject);



function destroyTimerOnClose(src,~,timerObject)
if  isvalid(timerObject)
   stop(timerObject);
   delete(timerObject);
end
closereq;

function readFiles(~, ~,obj,parent)
Files = {obj.remoteMonitorData.progdata.progressFiles};
Progr=cell(1,numel(Files));
% for ii=1:numel(Files)
%    fid=fopen(Files{ii},'rb');
%    if fid<0
%       fid=fopen(Files{ii},'wb');
%       fwrite(fid,0,'int8');
%       fclose(fid);
%       fid=fopen(Files{ii},'rb');
%    end
%    obj.remoteMonitorData.progdata(ii).fid=fid;
%    N = fread(fid,1,'int32');
%    if isempty(N),Progr{ii}=0;fclose(fid);continue;end
%    fseek(fid,0,'eof');
%    Progr{ii} = (ftell(fid)-4)/N;
%    disp(obj.qJobs{ii}.UserData);
%    fclose(fid);
% end
try
    for ii=1:numel(obj.qJobs)
        dName = fullfile(nigeLab.defaults.Tempdir,obj.qJobs{ii}.ID);
        warning off;diary(obj.qJobs{ii}, dName);warning on;
        fid=fopen(dName);
        obj.remoteMonitorData.progdata(ii).fid=fid;
        dString=fscanf(fid,'%s');
        ind = strfind(dString,'%');
        if ~isempty(ind)
            Progr{ii} = str2double(dString(ind(end)-3:ind(end)-1))/100;
        else
            Progr{ii} = 0;
        end
        fclose(fid);
    end
    
    obj.remoteMonitorData = progressbar(obj,parent,obj.remoteMonitorData,Files,Progr{:});
    drawnow;
catch
end


function data = progressbar(obj,nigelPanel,data,Files,varargin)


% Get inputs
input = varargin;
nbars = nargin-4;

% Define figure size and axes padding for the single bar case
height = 20;
nigelPanel.Units = 'pixels';
width = nigelPanel.InnerPosition(3)*0.6;
hoff = nigelPanel.InnerPosition(3)*0.05;
voff = nigelPanel.InnerPosition(4)*0.88;

% Create new progress bar if needed
if isempty(data)
  
   
   for ii = 1:nbars
      progdata(ii).progressFiles = Files{ii};
      % Create axes, patch, and text
      progdata(ii).progaxes = axes( ...
         'Units','pixels',...
         'Position', [0 0 width height], ...
         'XLim', [0 1], ...
         'YLim', [0 1], ...
         'Box', 'off', ...
         'ytick', [], ...
         'xtick', [],...
         'UserData',ii);
     
      set(progdata(ii).progaxes,'ButtonDownFcn',@AxBtnDownCallback)
      set(progdata(ii).progaxes,'UserData',false) %Initialise data
      
      progdata(ii).progpatch = patch(progdata(ii).progaxes, ...
         'XData', [0.3 0.3 0.3 0.3], ...
         'YData', [0   0   1   1  ],...
          'FaceColor',nigeLab.defaults.nigelColors(1));
      patch(progdata(ii).progaxes, ...
         'XData', [0 0.3 0.3 0], ...
         'YData', [0 0   1   1],...
         'FaceColor',nigeLab.defaults.nigelColors('surface'),...
         'EdgeColor',nigeLab.defaults.nigelColors('surface'));
      progdata(ii).progtext = text(progdata(ii).progaxes,0.99, 0.5, '', ...
         'HorizontalAlignment', 'Right', ...
         'FontUnits', 'Normalized', ...
         'FontSize', 0.7,...
         'FontName','Droid Sans');
      set(progdata(ii).progtext, 'String', '0%');
      progdata(ii).proglabel = text(progdata(ii).progaxes,0.01, 0.5, '', ...
         'HorizontalAlignment', 'Left', ...
         'FontUnits', 'Normalized', ...
         'FontSize', 0.7,...
         'Color',nigeLab.defaults.nigelColors('onsurface'),...
         'FontName','Droid Sans');
      ax = axes( ...
         'Units','pixels',...
         'Position', [width + 5 0 height height]);
      plot(ax,.5,.5,'x','MarkerSize',15,'LineWidth',3.5,...
         'Color',nigeLab.defaults.nigelColors(3),'ButtonDownFcn',{@DeleteBar,obj})
      set(ax, ...
         'XLim', [0 1], ...
         'YLim', [0 1], ...
         'Box', 'off', ...
         'Color',nigeLab.defaults.nigelColors(0.1),...
         'ytick', [], ...
         'xtick', [],...
         'UserData',ii,...
         'ButtonDownFcn',{@DeleteBar,obj});
      ax.XAxis.Visible='off';
      ax.YAxis.Visible='off';
      progdata(ii).X = ax;
      
      pos = [hoff voff-height*4/3*(ii-1) width + 5 + height height];
      pp = uipanel('BackgroundColor',nigeLab.defaults.nigelColors(0.1),...
          'Units','pixels','Position',pos,'BorderType','none');
      progdata(ii).progaxes.Parent=pp;
      ax.Parent=pp;
      nigelPanel.nestObj(pp);
      data.pp=pp;
      
      if ischar(input{ii})
         set(progdata(ii).proglabel, 'String', input{ii});
         progdata(ii).fractiondone = 0;
      end
      
      % Set starting time reference
      if ~isfield(progdata(ii), 'starttime') || isempty(progdata(ii).starttime)
         progdata(ii).starttime = clock;
      end
   end
   
   % Set time of last update to ensure a redraw
   lastupdate = clock - 1;
   
elseif ischar(input{1})
   progdata = data.progdata;
   voff = getpixelposition(data.pp);
   voff = voff(2);
   jj = 1;
   for ii = numel(progdata)+1:numel(progdata)+nbars
      progdata(ii).progressFiles = Files{jj};

      % Create axes, patch, and text
      progdata(ii).progaxes = axes( ...
         'Units','pixels',...
         'Position', [0 0 width height], ...
         'XLim', [0 1], ...
         'YLim', [0 1], ...
         'Box', 'off', ...
         'ytick', [], ...
         'xtick', [],...
         'UserData',ii);
      ax = axes( ...
         'Units','pixels',...
         'Position', [width + 5 0 height height]);
      p=plot(ax,.5,.5,'x','MarkerSize',15,'LineWidth',3.5,...
         'Color',nigeLab.defaults.nigelColors(3),'ButtonDownFcn',{@DeleteBar,obj});
      set(ax, ...
         'XLim', [0 1], ...
         'YLim', [0 1], ...
         'Box', 'off', ...
         'Color',nigeLab.defaults.nigelColors(0.1),...
         'ytick', [], ...
         'xtick', [],...
         'UserData',ii,...
         'ButtonDownFcn',{@DeleteBar,obj});
      ax.XAxis.Visible=false;ax.YAxis.Visible=false;
      progdata(ii).X = ax;
      
      pos = [hoff voff-height*4/3*(ii-1) width + 5 + height height];
      pp = uipanel('BackgroundColor',nigeLab.defaults.nigelColors(0.1),...
          'Units','pixels','Position',pos,'BorderType','none');
      progdata(ii).progaxes.Parent=pp;
      ax.Parent = pp;
      nigelPanel.nestObj(pp);
      
      progdata(ii).progpatch = patch(progdata(ii).progaxes, ...
         'XData', [0.3 0.3 0.3 0.3], ...
         'YData', [0   0   1   1  ],...
         'FaceColor',nigeLab.defaults.nigelColors(1));
      patch(progdata(ii).progaxes, ...
         'XData', [0 0.3 0.3 0], ...
         'YData', [0 0   1   1],...
         'FaceColor',nigeLab.defaults.nigelColors('surface'),...
         'EdgeColor',nigeLab.defaults.nigelColors('surface'));
      progdata(ii).progtext = text(progdata(ii).progaxes,0.99, 0.5, '', ...
         'HorizontalAlignment', 'Right', ...
         'FontUnits', 'Normalized', ...
         'FontSize', 0.7,'FontName','Droid Sans');
      set(progdata(ii).progtext, 'String', '0%');
      progdata(ii).proglabel = text(progdata(ii).progaxes,0.01, 0.5, '', ...
         'HorizontalAlignment', 'Left', ...
         'FontUnits', 'Normalized', ...
         'FontSize', 0.7,...
         'Color',nigeLab.defaults.nigelColors('onsurface'),...
         'FontName','Droid Sans');
      
      
      if ischar(input{jj})
         set(progdata(ii).proglabel, 'String', input{jj});
         progdata(ii).fractiondone = 0;
      end
      
      % Set starting time reference
      if ~isfield(progdata(ii), 'starttime') || isempty(progdata(ii).starttime)
         progdata(ii).starttime = clock;
      end
      jj=jj+1;
   end % ii
   
   
else
   
   progdata = data.progdata;
   % Process inputs and update state of progdata
   for ii = 1:nbars
      if ~isempty(input{ii})
         progdata(ii).fractiondone = input{ii};
         progdata(ii).clock = clock;
      end
   end
   
   % Enforce a minimum time interval between graphics updates
   myclock = clock;
   if abs(myclock(6) - data.lastupdate(6)) < 0.01 % Could use etime() but this is faster
      return
   end
   
   % Update progress patch
   offs = 0.3;
   for ii = 1:length(progdata)
      set(progdata(ii).progpatch, 'XData', ...
         [offs, offs+(1-offs)*progdata(ii).fractiondone, offs+(1-offs)*progdata(ii).fractiondone, 0.3]);
      set(progdata(ii).progtext, 'String', ...
            sprintf('%.3g%%', (100*progdata(ii).fractiondone)));
   end
   
   
   [~,ind] =min([progdata.fractiondone]);
   % Update progress figure title bar
   if progdata(ind).fractiondone > 0
      runtime = etime(progdata(ind).clock, progdata(ind).starttime);
      timeleft = runtime / progdata(ind).fractiondone - runtime;
      timeleftstr = sec2timestr(timeleft);
      titlebarstr = sprintf('%2d%%    %s remaining', ...
         floor(100*progdata(ind).fractiondone), timeleftstr);
   else
      titlebarstr = ' 0%';
   end
   
   % Force redraw to show changes
   drawnow
end

% Record time of this update
data.lastupdate = clock;
data.progdata = progdata;


% ------------------------------------------------------------------------------
function timestr = sec2timestr(sec)
% Convert a time measurement from seconds into a human readable string.

% Convert seconds to other units
w = floor(sec/604800); % Weeks
sec = sec - w*604800;
d = floor(sec/86400); % Days
sec = sec - d*86400;
h = floor(sec/3600); % Hours
sec = sec - h*3600;
m = floor(sec/60); % Minutes
sec = sec - m*60;
s = floor(sec); % Seconds

% Create time string
if w > 0
   if w > 9
      timestr = sprintf('%d week', w);
   else
      timestr = sprintf('%d week, %d day', w, d);
   end
elseif d > 0
   if d > 9
      timestr = sprintf('%d day', d);
   else
      timestr = sprintf('%d day, %d hr', d, h);
   end
elseif h > 0
   if h > 9
      timestr = sprintf('%d hr', h);
   else
      timestr = sprintf('%d hr, %d min', h, m);
   end
elseif m > 0
   if m > 9
      timestr = sprintf('%d min', m);
   else
      timestr = sprintf('%d min, %d sec', m, s);
   end
else
   timestr = sprintf('%d sec', s);
end

function DeleteBar(h,ev,obj)
if isa(h,'matlab.graphics.axis.Axes')
   ind = h.UserData;
else
   ind=h.Parent.UserData;
end
delete(h);
ax = obj.remoteMonitorData.progdata(ind).progaxes;
pace = (sum(ax.Position([1,3])))./10;
while sum(ax.Position([1,3]))>0
   ax.Position(1)= ax.Position(1)-pace;
   drawnow;
   pause(0.0005)
end
if ind==numel(obj.remoteMonitorData.progdata)
   delete(ax)
   obj.deleteJob(ind);
   fid = obj.remoteMonitorData.progdata(ind).fid;
   if ismember(fopen('all'),fid),fclose(fid);end
   delete(obj.remoteMonitorData.progdata(ind).progressFiles)
   obj.remoteMonitorData.progdata(ind) = [];
   if numel(obj.remoteMonitorData.progdata)==1
       stop(obj.remoteMonitorData.timerObject);
   end
   return;
end
Space = obj.remoteMonitorData.progdata(1).progaxes.Position(2) -...
   obj.remoteMonitorData.progdata(2).progaxes.Position(2);
for ii=ind+1: numel(obj.remoteMonitorData.progdata)
   obj.remoteMonitorData.progdata(ii).progaxes.Position(2) =...
      obj.remoteMonitorData.progdata(ii).progaxes.Position(2) + Space;
   obj.remoteMonitorData.progdata(ii).X.Position(2)=...
      obj.remoteMonitorData.progdata(ii).X.Position(2) + Space;
   obj.remoteMonitorData.progdata(ii).X.UserData = ii-1;
end
delete(ax)
fid = obj.remoteMonitorData.progdata(ind).fid;
if ismember(fopen('all'),fid),fclose(fid);end
delete(obj.remoteMonitorData.progdata(ind).progressFiles)
obj.remoteMonitorData.progdata(ind) = [];
obj.deleteJob(ind);
