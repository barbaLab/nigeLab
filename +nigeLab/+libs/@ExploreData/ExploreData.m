classdef ExploreData < handle
   
    properties
        ThisBlock
        UI
        ROI
    end
        
    methods
        
        function obj = ExploreData(nigelObj)
            
            switch nigelObj.Type
                case 'Block'
                    obj.ThisBlock = nigelObj;
                case 'Animal'
                    blIdx = randi(numel(nigelObj.Children));
                    nigeLab.libs.ExploreData(nigelObj{blIdx});
                case 'Tank'
                    anIdx = randi(numel(nigelObj.Children));
                    nigeLab.libs.ExploreData(nigelObj{anIdx});
            end     
                    
            obj.BuildGui();
            obj.addListeners();
            
        end
        
        function addListeners(obj)
            addlistener(obj.UI.DataScroller,'roiChanged',@obj.plotSnippets);
        end
        
        function plotSnippets(obj,src,evt)
            fs = obj.ThisBlock.SampleRate;
            obj.ROI = cumsum(floor(evt.ROI([1 3])*fs))+1;
            plotData(obj);
        end
        
        function BuildGui(obj)

            % Parse plottable fields
           Fields = obj.ThisBlock.getStatus;
           Fields_ = obj.ThisBlock.Fields;
           FieldsType_ = obj.ThisBlock.FieldType;
           Fields = Fields_(strcmp(FieldsType_,'Channels') & ismember(Fields_,Fields) );
           
           % Build gui
           obj.UI.DataSelector = obj.buildDataTypeSelector(Fields);           
           obj.UI.DataScroller = nigeLab.libs.DataScrollerAxis(obj.ThisBlock,'Raw');
            fs = obj.ThisBlock.SampleRate;
            
            obj.ROI = cumsum(floor(obj.UI.DataScroller.ROIpos([1 3])*fs))+1; % DataScroller.ROIpos is [xpos ypos width height]
            
            
            obj.UI.Fig = figure('Name','Multi-Channel Raw Snippets', ...
                'Units','Normalized', ...
                'Position',[0.05*rand+0.1,0.05*rand+0.1,0.8,0.8],...
                'Color','w','NumberTitle','off',...
                'CloseRequestFcn',@(~,~)obj.delete);
            
            obj.UI.MainAx = axes(obj.UI.Fig ,'NextPlot','add');            
            
            obj.plotData;
           
        end
        
        function str_box = buildDataTypeSelector(obj,Fields)
            
            % Create handle to store data and build graphics            
            obj.UI.DataSelectorFig = figure('Name','Data type selector', ...
                'Units', 'Normalized', ...
                'Position',[0.3 0.5 0.3 0.3],...
                'MenuBar','none',...
                'ToolBar','none',...
                'NumberTitle','off');
            fig = obj.UI.DataSelectorFig;
            
            p = nigeLab.libs.nigelPanel(fig,...
                'String','Data type selector',...
                'Tag','uidropdownbox',...
                'Units','normalized',...
                'Position',[0 0 1 1],...
                'Scrollable','off',...
                'PanelColor',nigeLab.defaults.nigelColors('surface'),...
                'TitleBarColor',nigeLab.defaults.nigelColors('tertiary'),...
                'TitleColor',nigeLab.defaults.nigelColors('ontertiary'));
            
            prompt_text = uicontrol('Style','text',...
                'Units','Normalized', ...
                'Position',[0.2 0.775 0.6 0.20],...
                'FontSize', 22, ...
                'FontWeight','bold',...
                'FontName','Droid Sans',...
                'BackgroundColor',nigeLab.defaults.nigelColors('surface'),...
                'ForegroundColor',nigeLab.defaults.nigelColors('tertiary'),...
                'String','Select a field.');
            p.nestObj(prompt_text);
            
            str_box = uicontrol('Style','popupmenu',...
                'Units', 'Normalized', ...
                'Position',[0.05 0.4 0.9 0.30],...
                'FontSize', 16, ...
                'FontName','Droid Sans',...
                'String',Fields,...
                'Callback',@(~,~)obj.changeDataTyoe);
            
            p.nestObj(str_box);
        end
        
        function delete(obj)
            
            delete(obj.UI.DataSelector);
            delete(obj.UI.DataSelectorFig);
            delete(obj.UI.DataScroller);
            delete(obj.UI.MainAx);
            delete(obj.UI.Fig);
        end
        
        function changeDataTyoe(obj)
            idx = obj.UI.DataSelector.Value;
            Field = obj.UI.DataSelector.String{idx};
            obj.UI.DataScroller.changeDataType(Field);
            obj.plotData();
        end
        
        
        function plotData(obj)
            
            idx = obj.UI.DataSelector.Value;
            Field = obj.UI.DataSelector.String{idx};
            cla(obj.UI.MainAx);
            obj.UI.Fig.Name = sprintf('Multi-Channel %s Snippets',Field);
            obj.ThisBlock.plotWaves(obj.UI.MainAx,...
                Field,obj.ROI(1):obj.ROI(2));
                    
        end
        
    end
        
end