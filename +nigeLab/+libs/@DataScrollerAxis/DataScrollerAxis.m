classdef DataScrollerAxis < handle
    
    properties
        Field
        UI
        channel
        ThisBlock
        Channels
        MainAxPixelSize
        sigLenght
        fs
        ROIpos = zeros(1,4)
        LinePlotExplorer
        ReducedPlot
        
        Listeners
    end
    
    events
        roiChanged
    end
    
    methods 
        
        function obj = DataScrollerAxis(nigelObj,Field)
            % DATASCROLLERAXIS  Axes that allows selecting intresting
            % portions of data from a channel. 
            % this makes use of nigeLab.utils.LinePlotReducer to reduce the
            % number of points plotted to the bare minimum to represent all
            % the feature of the signal
            %
            %  ax = nigeLab.libs.TimeScrollerAxes(nigelObj,Field);
            %  nigelObj can be any nigelObj but it will always sample down
            %  a block to plot the actual data
            %  Field the actual field to plot.
            
            if nargin < 2
                Field = 'Filt';
            end
            
            switch nigelObj.Type
                case 'Tank'
                    anIdx = randi(numel(nigelObj.Children));
                    obj = nigeLab.libs.DataScrollerAxis(nigelObj{anIdx},Field);
                    return
                case 'Animal'
                    blIdx = randi(numel(nigelObj.Children));
                    obj = nigeLab.libs.DataScrollerAxis(nigelObj{blIdx},Field);
                    return
                case 'Block'
                    obj.ThisBlock = nigelObj;
            end
            

            obj.buildGui();
            changeDataType(obj,Field);
            obj.buildROI();
            obj.addListeners();
        end
        
        function addListeners(obj)
            %% Add all needed listeners here
            obj.Listeners = [obj.Listeners, ...
                addlistener(obj.UI.ChannelSelector,'NewChannel',...
                @obj.setChannel)];
        end
        
        function delete(obj)
           delete(obj.UI.ChannelSelector);
           delete(obj.UI.Fig);
        end
        
        function buildGui(obj)
            obj.UI.Fig = figure('Units','normalized',...
                'Position',[.1 .1 .8 .25],...
                'DeleteFcn',@(~,~)obj.delete,...
                'MenuBar','figure',...
                'NumberTitle','off',...
                'WindowButtonUpFcn',@(~,~)obj.RoiChanged);
            
            obj.UI.MainAx = axes(obj.UI.Fig,'Units','normalized','Position',[.02 .1 .94 .85]);
            obj.MainAxPixelSize =  getpixelposition(obj.UI.MainAx);
            
            obj.Channels.Name = {obj.ThisBlock.Channels.name};
            obj.Channels.Selected = 1;
            obj.UI.Parent = obj;
            obj.UI.channel = 1;
            
            obj.UI.ChannelSelector = nigeLab.libs.ChannelUI(obj.UI);
            
        end
        
        function buildROI(obj,pos)
            if nargin < 2
                yl = ylim(obj.UI.MainAx);
                xl = xlim(obj.UI.MainAx);
                xmax = min(obj.sigLenght,60*obj.fs)./obj.fs;
                obj.ROIpos = [xl(1) yl(1) xmax diff(yl)];
            else
                yl = ylim(obj.UI.MainAx);
                obj.ROIpos = pos;
            end
            % builds ROI overlay on top of the datascroller

            obj.UI.ROI = imrect(obj.UI.MainAx,obj.ROIpos,...
                'PositionConstraintFcn',@obj.roiResizeFcn); %#ok<IMRECT>
            setColor(obj.UI.ROI,nigeLab.defaults.nigelColors('red'));
            ylim(obj.UI.MainAx,yl);

        end
        
        function newPos = roiResizeFcn(obj,pos)
            newPos = pos;
            yl = ylim(obj.UI.MainAx);
            xl = xlim(obj.UI.MainAx);
            
            maxWidth = xl(2) - pos(1);

            % fix ROI height           
            newPos([2 4]) = [yl(1) diff(yl)];
            
            
            % fix ROI width
            newPos(3) = min(maxWidth,newPos(3));
            
            % fix ROI starting x
            newPos(1) = max(xl(1),newPos(1));       % minimum
            a = newPos(1) - (xl(2)-newPos(3)) >= 0;
            newPos = a.*obj.ROIpos + (1-a).*newPos;
%             newPos(1) = min(xl(2)-newPos(3),newPos(1));       % maximum

            obj.ROIpos = newPos;
            
        end
        
        function plotData(obj)
            obj.fs = obj.ThisBlock.SampleRate;
           if strcmp(obj.Field,'LFP')
               obj.fs = obj.ThisBlock.Pars.LFP.DownSampledRate;
           end
            data = obj.ThisBlock.Channels(obj.Channels.Selected).(obj.Field)(:);
            obj.sigLenght = numel(data);
            if obj.ThisBlock.getStatus('Time') && ~isempty(obj.ThisBlock.Time)
                tt = obj.ThisBlock.Time(:);
            else
                tt = linspace(0,obj.sigLenght./obj.fs,obj.sigLenght);
            end
            
            if isempty(tt) || length(tt)~=obj.sigLenght
                %failsafe
                tt = linspace(0,obj.sigLenght./obj.fs,obj.sigLenght);
            end
            [x_reduced, y_reduced] = nigeLab.utils.reduce_to_width(tt, data, obj.MainAxPixelSize(4) ,[tt(1) tt(end)]);
            cla(obj.UI.MainAx);
            L = line(obj.UI.MainAx,x_reduced,y_reduced);
            obj.ReducedPlot = nigeLab.utils.LinePlotReducer(L,tt,data);
            xlim(obj.UI.MainAx,[tt(1) tt(end)]);
%             obj.LinePlotExplorer = nigeLab.utils.LinePlotExplorer(obj.UI.Fig);
            
        end
        
        function RoiChanged(obj)
            evt = nigeLab.evt.dataScrolled(obj.ROIpos);
            notify(obj,'roiChanged',evt);
        end
        
        function setChannel(obj,src,~)
            obj.Channels.Selected = src.Channel;
            plotData(obj);
            obj.buildROI(obj.ROIpos);
        end
        
        function flag = set(obj,field,value)
           % compatibility function foir the channel selector 
           
           flag = true;
           
           switch field
               case 'channel'
                   obj.channel = value;
                   flag = true;
           end
        end
        
        function flag = changeDataType(obj,type)
            flag = false;
             stepDone = obj.ThisBlock.getStatus;
            if ~any(strcmp(stepDone,type))
                error('%s field hasn''t been computed yet.',obj.Field);
            end
            
            obj.Field = type;
            obj.plotData();
            obj.buildROI(obj.ROIpos);
            flag = true;
        end
        
    end
    
end