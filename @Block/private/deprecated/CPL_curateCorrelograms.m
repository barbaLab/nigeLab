function CPL_curateCorrelograms(corr_data,varargin)
%% CPL_CURATECORRELOGRAMS  Manually curate inhibitory/excitatory interactions.
%
%  CPL_CURATECORRELOGRAMS(rel,'NAME',value,...)
%
%  --------
%   INPUTS
%  --------
%  corr_data    :     Struct from CPL_GETXCORR
%
%  varargin :     (Optional) 'NAME', value input arguments (or parameters
%                             struct).
%
% By: Max Murphy  v1.0  03/22/2018  Original version (R2017b)

%% DEFAULTS
p = struct;

% Panelized axes params
p.axes = struct;
p.axes.n = 9;
p.axes.xOffset = 0.025;
p.axes.yOffset = 0.025;
p.axes.xlim = [min(corr_data(1).tau) max(corr_data(1).tau)];
p.axes.ylim = [0 1];

% Plotting parameters
p.plot.bgcol = {[1,1,1]; [0 0 1]; [0.2 0.2 0.8]; [1 0 0]; [0.8 0.2 0.2]};
p.plot.fcol = {[0.5 0.5 0.5]; [0 0 0]; [0 0 0]; [1 1 1]; [1 1 1]};

p.plot.Opts = {'None'; ...
               'Excites'; ...
               'Is Excited'; ...
               'Inhibits'; ...
               'Is Inhibited'};
p.plot.tau = corr_data(1).tau;            

% Saving parameters
p.save.dir = fullfile(pwd,'Data','XCorr');
p.save.name = 'RLM_CuratedXCorr_Data.mat';

%% PARSE VARARGIN
if numel(varargin) > 1
   for iV = 1:2:numel(varargin)
      p.(varargin{iV}) = varargin{iV+1};
   end
else
   if numel(varargin) > 0
      p = varargin{1};
   end
end

%% CONSTRUCT INTERFACE
fig = figure('Name','Correlogram curation tool',...
             'Units','Normalized',...
             'Color','w',...
             'Position',[0.1 0.1 0.8 0.8],...
             'MenuBar','none',...
             'ToolBar','none',...
             'NumberTitle','off');
          
ctl_pnl = uipanel(fig,'Units','Normalized',...
                      'Position',[0.8 0.025 0.175 0.95]);

rad_pnl = uipanel(ctl_pnl,'Units','Normalized',...
                          'Position',[0.025 0.5 0.95 0.4],...
                          'FontName','Arial',...
                          'Title','Type Selection');
                   
plt_pnl = uipanel(fig,'Units','Normalized',...
                      'Position',[0.025 0.025 0.75 0.95],...
                      'FontName','Arial',...
                      'FontSize',16,...
                      'Title','Correlograms');

% Panelize axes and radio buttons
ax = uiPanelizeAxes(plt_pnl,p.axes.n,p.axes.xOffset,p.axes.yOffset,...
                            'XLIM',p.axes.xlim,...
                            'YLIM',p.axes.ylim);

selectionData = struct('cur',1,...
                       'idx',ones(numel(corr_data),1),...
                       'sub',1:p.axes.n);
                       
bg = uiAxesSelectionRadio(rad_pnl,p.plot.Opts,selectionData);

tx = uicontrol(ctl_pnl,'Style','text',...
                       'Units','Normalized',...
                       'Position',[0.025 0.915 0.95 0.075],...
                       'FontName','Arial',...
                       'FontSize',14,...
                       'String',sprintf('%d of %d pairs viewed',...
                                 p.axes.n,numel(corr_data)),...
                       'UserData',p.axes.n);

% Make navigation buttons
uicontrol(ctl_pnl,'Style','pushbutton',...
          'Units','Normalized',...
          'Position',[0.25 0.025 0.5 0.125],...
          'FontName','Arial',...
          'FontSize',14,...
          'BackgroundColor','y',...
          'ForegroundColor','k',...
          'String','Save',...
          'Callback',{@savePush,bg,p});
       
uicontrol(ctl_pnl,'Style','pushbutton',...
          'Units','Normalized',...
          'Position',[0.25 0.175 0.5 0.125],...
          'FontName','Arial',...
          'FontSize',14,...
          'BackgroundColor',[0.75 0.3 0.3],...
          'ForegroundColor','w',...
          'String','Prev',...
          'Callback',{@prevPush,bg,ax,p,corr_data,tx});
       
uicontrol(ctl_pnl,'Style','pushbutton',...
          'Units','Normalized',...
          'Position',[0.25 0.325 0.5 0.125],...
          'FontName','Arial',...
          'FontSize',14,...
          'BackgroundColor',[0.3 0.3 0.75],...
          'ForegroundColor','k',...
          'String','Next',...
          'Callback',{@nextPush,bg,ax,p,corr_data,tx});

for iAx = 1:p.axes.n
   ax{iAx}.ButtonDownFcn = {@selAx,bg,p};
end

plotAx(bg,ax,p,corr_data);
fig.KeyPressFcn = {@shortKey,bg,ax,p,corr_data,tx};

%% FUNCTIONS
   function savePush(~,~,s,p)
      if exist(p.save.dir,'dir')==0
         mkdir(p.save.dir);
      end
      
      fname = fullfile(p.save.dir,p.save.name);
      if exist(fname,'file')~=0
         str = questdlg('Overwrite existing file?','Overwrite?',...
                        'Yes','Cancel','Yes');
      else
         str = 'Yes';
      end
      
      if strcmp(str,'Yes')
         idx = s.UserData.idx;
         classnames = p.plot.Opts;
         save(fname,'idx','classnames','-v7.3');
         delete(gcf);         
      end
   end

   function prevPush(~,~,s,ax,p,rel,tx)
      n = p.axes.n;
      
      s.UserData.sub = s.UserData.sub - n;
      while min(s.UserData.sub) < 1
         s.UserData.sub = s.UserData.sub + 1;
      end
            
      plotAx(s,ax,p,rel);
      tx.String = sprintf('%d of %d pairs viewed',...
                           tx.UserData,...
                           numel(rel));
   end

   function nextPush(~,~,s,ax,p,rel,tx)
      n = p.axes.n;
      N = numel(rel);
      
      s.UserData.sub = s.UserData.sub + n;
      while max(s.UserData.sub) > N
         s.UserData.sub = s.UserData.sub - 1;
      end
      
      plotAx(s,ax,p,rel);
      tx.UserData = max(tx.UserData,max(s.UserData.sub));
      tx.String = sprintf('%d of %d pairs viewed',...
                           tx.UserData,...
                           numel(rel));
                        
      
   end

   function selAx(src,~,s,p)
      u = s.UserData;
      if isa(src,'matlab.graphics.chart.primitive.Bar')
         thisAx = src.Parent;
         thisBar = src;
      else
         thisAx = src;
         if ~isempty(src.Children)
            thisBar = src.Children(1);
         else
            thisBar = [];
         end
      end
      
      thisAx.Color = p.plot.bgcol{u.cur};
      if ~isempty(thisBar)
         thisBar.FaceColor = p.plot.fcol{u.cur};
      end
      
      s.UserData.idx(u.sub(thisAx.UserData)) = u.cur;
   end

   function plotAx(s,ax,p,rel)
      axCount = 1;
      u = s.UserData;
      for ii = u.sub
         ax{axCount}.Color = p.plot.bgcol{u.idx(ii)};
         bar(ax{axCount},p.plot.tau,rel(ii).xcorr,1,...
            'EdgeColor','none',...
            'FaceColor',p.plot.fcol{u.idx(ii)},...
            'ButtonDownFcn',{@selAx,s,p});
         axCount = axCount + 1;
      end
   end

   function shortKey(~,evt,bg,ax,p,rel,tx)
      switch evt.Key
         case 's'
            bg.UserData.cur = min(bg.UserData.cur + 1, numel(p.plot.Opts));
            set(bg,'SelectedObject',bg.UserData.b{bg.UserData.cur});
         case 'downarrow'
            bg.UserData.cur = min(bg.UserData.cur + 1, numel(p.plot.Opts));
            set(bg,'SelectedObject',bg.UserData.b{bg.UserData.cur});
         case 'w'
            bg.UserData.cur = max(bg.UserData.cur - 1, 1);
            set(bg,'SelectedObject',bg.UserData.b{bg.UserData.cur});
         case 'uparrow'
            bg.UserData.cur = max(bg.UserData.cur - 1, 1);
            set(bg,'SelectedObject',bg.UserData.b{bg.UserData.cur});
         case 'a'
            prevPush(nan,nan,bg,ax,p,rel,tx);
         case 'leftarrow'
            prevPush(nan,nan,bg,ax,p,rel,tx);
         case 'd'
            nextPush(nan,nan,bg,ax,p,rel,tx);
         case 'rightarrow'         
            nextPush(nan,nan,bg,ax,p,rel,tx);
      end
   end

end