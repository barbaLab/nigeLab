classdef remoteMonitor < handle
    %REMOTEMONITOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        qPanel
        
        height = 20;
        width
        hoff
        voff
        
        progtimer
        bars
        
        pars
    end
    
    methods
        function obj = remoteMonitor(panel)
            
            % qPanle needs to be a nigelPanel
            if regexp(class(panel),'nigelPanel[ (\w*)]')
                obj.qPanel = panel;
            elseif regexp(class(panel),'matlab.ui.container.Panel')
                p=nigeLab.libs.nigelPanel(panel,...
                    'String','Remote Monitor','Tag','monitor','Position',[0 0 1 1],...
                    'PanelColor',nigeLab.defaults.nigelColors('surface'),...
                    'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
                    'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
                obj.qPanel = p;
            elseif regexp(class(panel),'matlab.ui.Figure')
                p=nigeLab.libs.nigelPanel(panel,...
                    'String','Remote Monitor','Tag','monitor','Position',[0 0 1 1],...
                    'PanelColor',nigeLab.defaults.nigelColors('surface'),...
                    'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
                    'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
                obj.qPanel = p;
            else
               error('Wrong input argoument. Panel needs to be a figure a ui panel or a nigelPanel'); 
            end
            
            % Define figure size and axes padding for the single bar case
            pos = obj.qPanel.getPixelPosition();
            obj.width = pos(3)*0.8;
            obj.hoff = pos(3)*0.05;
            obj.voff = pos(4)*0.88;
            
            obj.pars = nigeLab.defaults.Notifications();
            
            
            obj.progtimer = timer('Name',sprintf('%s_timer','remoteMonitor'),...
                'Period',obj.pars.NotifyTimer,...
                'ExecutionMode','fixedSpacing',...
                'TimerFcn',@(~,~)obj.updateRemoteMonitor);
            
            cc = {'idx'
                  'job'
                  'starttime'
                  'progaxes'
                  'progpatch'
                  'progtext'
                  'proglabel'
                  'X'
                  'containerPanel'}';
              cc{2,1}={};
              obj.bars = struct(cc{:});
        end
        
        function delete(obj)
            stop(obj.progtimer);
            delete(obj.progtimer);
            delete(obj);
        end
        
        function addBar(monitorObj,name,job)
            nBars = numel(monitorObj.bars);
            idx = nBars+1;
            
            bar.idx = idx;
            bar.job = job;
            
            % Set starting time reference
            if ~isfield(bar, 'starttime') || isempty(bar.starttime)
                bar.starttime = clock;
            end
            
            %%%% Design and plot the progressbars
            bar.progaxes = axes( ...
                'Units','pixels',...
                'Position', [0 0 monitorObj.width monitorObj.height], ...
                'XLim', [0 1], ...
                'YLim', [0 1], ...
                'Box', 'off', ...
                'ytick', [], ...
                'xtick', [],...
                'UserData',idx);
            
            bar.progpatch = patch(bar.progaxes, ...
                'XData', [0.5 0.5 0.5 0.5], ...
                'YData', [0   0   1   1  ],...
                'FaceColor',nigeLab.defaults.nigelColors(1));
            
            patch(bar.progaxes, ...
                'XData', [0 0.5 0.5 0], ...
                'YData', [0 0   1   1],...
                'FaceColor',nigeLab.defaults.nigelColors('surface'),...
                'EdgeColor',nigeLab.defaults.nigelColors('surface'));
            
           
            bar.progtext = text(bar.progaxes,0.99, 0.5, '', ...
                'HorizontalAlignment', 'Right', ...
                'FontUnits', 'Normalized', ...
                'FontSize', 0.7,...
                'FontName','Droid Sans');            
            set(bar.progtext, 'String', '0%');
            
            bar.proglabel = text(bar.progaxes,0.01, 0.5, '', ...
                'HorizontalAlignment', 'Left', ...
                'FontUnits', 'Normalized', ...
                'FontSize', 0.7,...
                'Color',nigeLab.defaults.nigelColors('onsurface'),...
                'FontName','Droid Sans');
            set(bar.proglabel,'String',name);
            
            %%%% Design and plot the cancel button

            XButton = uicontrol('Style','pushbutton',...
                'Units','pixels',...
                'Position', [monitorObj.width + 5 0 monitorObj.height monitorObj.height],...
                'BackgroundColor',nigeLab.defaults.nigelColors(0.1),...
                'ForegroundColor',nigeLab.defaults.nigelColors(3),...
                'String','X');

%             ax = axes( ...
%                 'Units','pixels',...
%                 'Position', [monitorObj.width + 5 0 monitorObj.height monitorObj.height]);
%             plot(ax,.5,.5,'x','MarkerSize',15,'LineWidth',3.5,...
%          'Color',nigeLab.defaults.nigelColors(3))
%             set(ax, ...
%                 'XLim', [0 1], ...
%                 'YLim', [0 1], ...
%                 'Box', 'off', ...
%                 'Color',nigeLab.defaults.nigelColors(0.1),...
%                 'ytick', [], ...
%                 'xtick', [],...
%                 'UserData',idx);
%             
%             ax.XAxis.Visible='off';
%             ax.YAxis.Visible='off';
            bar.X = XButton;
            
            
            
            
            %%%% enclose everything in a panel
            % this is convenient for stacking purposes
            pos = [monitorObj.hoff monitorObj.voff-monitorObj.height*4/3*(idx-1) monitorObj.width + 5 + monitorObj.height monitorObj.height];
            pp = uipanel('BackgroundColor',nigeLab.defaults.nigelColors(0.1),...
                'Units','pixels','Position',pos,'BorderType','none');
            bar.progaxes.Parent=pp;
            bar.X.Parent=pp;
            bar.containerPanel = pp;
            %%% Nest the panel in in the nigelpanel
            monitorObj.qPanel.nestObj(bar.containerPanel,sprintf('ProgressBar_%02d',idx));
            
            %%% store the bars in the remoteMonitor obj
            monitorObj.bars(idx)=bar;
            set(XButton,'Callback',{@(~,~,bar)monitorObj.deleteBar(bar),bar})
            jObj = nigeLab.utils.findjobj(XButton);
            jObj.setBorder(javax.swing.BorderFactory.createEmptyBorder());
            jObj.setBorderPainted(false);
            
            %%% if first bar we need to start timer
            if strcmp(monitorObj.progtimer.Running,'off')
               start(monitorObj.progtimer); 
            end
        end
        
        function updateRemoteMonitor(monitorObj)
            try
            for ii=1:numel(monitorObj.bars)
                bar = monitorObj.bars(ii);
                [pct,str] = nigeLab.utils.jobTag2Pct(bar.job);
                
                % Get the offset of the progressbar from the left of the panel
                xStart = bar.progpatch.XData(1);
                
                % Compute how far the bar should be filled based on the percent
                % completion, accounting for offset from left of panel
                xStop = xStart + (1-xStart) * (pct/100);
                
                % Redraw the patch that colors in the progressbar
                bar.progpatch.XData = ...
                    [xStart, xStop, xStop, xStart];
                bar.progtext.String = ...
                    sprintf('%.3g%%',pct);
                bar.proglabel.String = str;
                drawnow;
                
                % If the job is completed, then run the completion method
%                 if pct == 100
%                     monitorObj.barCompleted;
%                 end
                
            end
            catch
                ...
            end
        end
        
        function deleteBar(monitorObj,bar)
            stop(monitorObj.progtimer); % to prevent graphical updates errors
            
            ind =  bar.progaxes.UserData;
            delete(bar.containerPanel);
            for jj=ind+1:numel(monitorObj.bars)
                monitorObj.bars(jj).progaxes.UserData= jj-1;
                pos = [monitorObj.hoff monitorObj.voff-monitorObj.height*4/3*(jj-2) monitorObj.width + 5 + monitorObj.height monitorObj.height];
                monitorObj.bars(jj).containerPanel.Position = pos;
            end
            try
                cancel(bar.job);
                delete(bar.job);
            end
            monitorObj.bars(ind) = [];
            
            if numel(monitorObj.bars) > 0
                start(monitorObj.progtimer);
            end
        end
        
        function barCompleted(monitorObj)
            nigeLab.sounds.play('bell',1.5);
 
        end
        

    end
    
end

