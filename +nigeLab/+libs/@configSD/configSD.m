classdef configSD < handle
   %% CONFIGSD class. It summons a UI where you can configure the SD parameters prior to SD execution
   properties
       Fig
       DataAx
       SpikeAx
       SDParsPanel
       ArtRejParsPanel
       BtnPanel
       SliderLbl
       durSlider
       SDBtn
       
       ExBlock
       SDMethods
       Pars 
       
       startIdx
       endIdx
       chanIdx
   end
   
   
   methods
       
       function obj = configSD(nigelObj)
           switch nigelObj.Type
               case 'Tank'
                   idxA = randi(numel(nigelObj.Children));
                   idxB = randi(numel(nigelObj.Children(idxA).Children));
                   obj.ExBlock = nigelObj{idxA,idxB};
               case 'Animal'
                   idx = randi(numel(nigelObj.Children));
                   obj.ExBlock = nigelObj{idx};
               case 'Block'
                   obj.ExBlock = nigelObj;
           end
           
           ff = fieldnames(obj.ExBlock.Pars.SD);
           obj.SDMethods = ff(cellfun(@(fName)numel(fName)>2 && strcmp(fName(1:3),'SD_') ,ff));
           
           obj.SDMethods = cellfun(@(MName) MName(4:end),obj.SDMethods, 'UniformOutput',false);
           
           obj.Pars = obj.ExBlock.Pars.SD;
           
           % Build UI
           obj.buildGUI();
           obj.Fig.Visible = 'on';
           
           obj.renderData()
           
       end
       
       function renderData(obj)
          
           thisBlock = obj.ExBlock;
           
           L = thisBlock.Samples;
           fs = thisBlock.SampleRate;
           MaxSamples = 10*60*fs; % 10 minutes max recording
           obj.startIdx = randi(max(1,L-MaxSamples));           
           obj.endIdx = min(L,obj.startIdx+MaxSamples);
           obj.chanIdx = randi(thisBlock.NumChannels);
           if obj.endIdx == L
               obj.durSlider.Enable = 'off';
              obj.SliderLbl.Enable = 'off'; 
           end
           
           t = (obj.startIdx:obj.endIdx)./fs;
           data = thisBlock.Channels(obj.chanIdx).Filt(obj.startIdx:obj.endIdx);
           plot(obj.DataAx,t,data);
           xlim(obj.DataAx,[t(1) min(t(1)+60,t(end))]);
           obj.DataAx.YAxis.Color = [1,1,1];obj.DataAx.XAxis.Color = [1,1,1];
           title(obj.DataAx,'Filtered Data','Color',[1 1 1]);

       end
       
       function delete(obj)
           
       end
       
       function buildGUI(obj,fig)
           % BUILDGUI  Build the graphical interface
         %
         %  fig = obj.buildGUI(); Constructs new figure and adds panels
         %
         %  fig = obj.buildGUI(fig);  Adds the panels only
         
         if nargin < 2
            obj.Fig = figure(...
               'Toolbar','auto',...
               'MenuBar','none',...
               'NumberTitle','off',...
               'Units','pixels',...
               'Position',[1500 200 800 700],...
               'Color',nigeLab.defaults.nigelColors('bg'),...
               'Visible','off');
           fig = obj.Fig;
         else
            obj.Fig = fig; 
         end
         
         
         obj.DataAx = axes(fig,'Units','normalized','Position',[.05 .7   .9 .25],'Box','off');

         obj.SpikeAx = axes(fig,'Units','normalized','Position',[.75 .35   .2 .28],'Box','off');
         title(obj.SpikeAx,'Spikes','Color',[1 1 1]);

         obj.SpikeAx.YAxis.Color = [1,1,1];obj.SpikeAx.XAxis.Color = [1,1,1];
         obj.BtnPanel =uipanel(fig,'Position',[.75 .05   .2 .25]);
         

         obj.SliderLbl = uicontrol(obj.BtnPanel,'Style','text',...
             'Units','normalized',...
             'Position',[.1 .7 .8 .1],...
             'String','1 min',...
             'HorizontalAlignment','left');
         obj.durSlider  = uicontrol(obj.BtnPanel,'Style','slider',...
             'Units','normalized',...
             'Position',[.1 .8 .8 .15],...
             'Value',1,'Min',1,'Max',10,...
             'Callback',@(hObj,~,~)obj.changeDataLim(hObj));
         obj.SDBtn = uicontrol(obj.BtnPanel,'Style','pushbutton','String','Detect!',...
             'Units','normalized',...
             'Position',[.1 .1 .35 .2],...
             'Callback',@(~,~)obj.StartSD);
         
         obj.SDParsPanel = uitabgroup(fig,...
            'Units','normalized',...
            'Position',[.05 .25  .65 .4]);
        
        obj.ArtRejParsPanel = uitabgroup(fig,...
            'Units','normalized',...
            'Position',[.05 .05  .65 .18]);
        
        for ii = 1:numel(obj.SDMethods)
           % Add all uitabs
           thisTab = uitab(obj.SDParsPanel,'Title',obj.SDMethods{ii},'Scrollable','on');
           thisPars = (obj.ExBlock.Pars.SD.(['SD_' obj.SDMethods{ii}]));
           thisParsNames = fieldnames(thisPars);
           thisTab.Units = 'pixels';
           Width = thisTab.InnerPosition(3);
           thisTab.Units = 'normalized';
           for jj=1:numel(thisParsNames)
               Hoff = floor(Width/3)*mod(jj-1,3);
               Woff = -40*idivide(int16(jj-1),3);
             thisParText =  uicontrol('Style','edit',...
                  'Parent',thisTab,...
                  'Units','pixels',...
                  'Position',[38 + Hoff   215 + Woff   37   18],...
                  'String',nigeLab.utils.ToString(thisPars.(thisParsNames{jj})),...
                  'Callback',@(hObj,~,~)textBoxCallback(obj,hObj,obj.SDMethods{ii},thisParsNames{jj}));
              
              thisParLbl =  uicontrol('Style','text',...
                  'Parent',thisTab,...
                  'Units','pixels',...
                  'Position',[38 + Hoff  235 + Woff   70   18],...
                  'String',thisParsNames{jj},...
                  'HorizontalAlignment','left');
              
           end
        end
         
       end
       
       function textBoxCallback(obj,hObj,MethodName,ParName)
           val = get(hObj,'String');
           thiPar = obj.ExBlock.Pars.SD.(['SD_' MethodName]).(ParName);
           
           if isnumeric(thiPar)
               convertedVal = str2double(val);
               
           elseif isa(thiPar,'function_handle')
               if ismember(exist(thiPar),[2 3 5 6])
                   convertedVal = str2func(val);
               else
                   error('The defined function does not exist!/n');
               end
               
           elseif ischar(thiPar)
               convertedVal = val;
               
           end
           
           obj.Pars.(MethodName).(['SD_' MethodName]) = convertedVal;
       end
       
       function changeDataLim(obj,hobj)
           val = hobj.Value;
           obj.DataAx.XLim(2) = obj.DataAx.XLim(1) + val*60;
           obj.SliderLbl.String = sprintf('%.2f Min',val);
       end
       
       function StartSD(obj)
           AlgName = obj.SDParsPanel.SelectedTab.Title;
           SDFun = ['SD_' AlgName];
           SDPars = obj.Pars.(SDFun);
           SDPars.fs = obj.ExBlock.SampleRate;
           data = obj.ExBlock.Channels(obj.chanIdx).Filt(obj.startIdx:obj.endIdx);
           SDargsout = obj.ExBlock.testSD(SDFun,data,SDPars);
           
           tIdx        = SDargsout{1};
           peak2peak = SDargsout{2};
           peakAmpl  = SDargsout{3};
           peakWidth = SDargsout{4};
           
            plotSpikes(obj,tIdx,peakAmpl,peakWidth)
       end
       
       function plotSpikes(obj,tIdx,peakAmpl,peakWidth)
           fs = obj.ExBlock.SampleRate;
           t = (obj.startIdx:obj.endIdx)./fs;
           
           data = obj.ExBlock.Channels(obj.chanIdx).Filt(obj.startIdx:obj.endIdx);
           WindowPreSamples =  obj.Pars.WPre * 1e-3 * fs;
           WindowPostSamples =  obj.Pars.WPost * 1e-3 * fs;
           out_of_record = tIdx <= WindowPreSamples+1 | tIdx >= length(data) - WindowPostSamples - 2;
          
           peakAmpl(out_of_record) = [];
           peakWidth(out_of_record) = [];
           tIdx(out_of_record) = [];
           
           
           hold(obj.DataAx,'on');
           plot(obj.DataAx,t(tIdx),peakAmpl,'*r')
           
           % BUILD SPIKE SNIPPET ARRAY AND PEAK_TRAIN
           tIdx = tIdx(:); % make sure it's vertical
           if (any(tIdx)) % If there are spikes in the current signal
               snippetIdx = (-WindowPreSamples : WindowPostSamples) + tIdx;
               spikes = data(snippetIdx);
               plot(obj.SpikeAx,(-WindowPreSamples : WindowPostSamples)./fs,spikes);
               obj.SpikeAx.YAxis.Color = [1,1,1];obj.SpikeAx.XAxis.Color = [1,1,1];
           end
           
           title(obj.SpikeAx,'Spikes','Color',[1 1 1]);

       end
       
   end
   
   
end