classdef configSD < handle
   %% CONFIGSD class. It summons a UI where you can configure the SD parameters prior to SD execution
   properties
       UI
       Listeners
       Channels
       
       Fig
       DataAx
       artPlot
       spkPlot
       
       SpikeAx
       SDParsPanel
       ArtRejParsPanel
       BtnPanel
       SliderLbl
       durSlider
       SDBtn
       ARTBtn
       ZoomBtn
       
       ExBlock
       SDMethods
       ARTMethods
       Pars 
       
       startIdx
       endIdx
       
       data
       artRejData
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
           
           obj.ARTMethods = ff(cellfun(@(fName)numel(fName)>2 && strcmp(fName(1:4),'ART_') ,ff));
           obj.ARTMethods = cellfun(@(MName) MName(5:end),obj.ARTMethods, 'UniformOutput',false);
           
           obj.Pars = obj.ExBlock.Pars.SD;
           
           % Build UI
           obj.buildGUI();
           
           obj.Channels.Name = {obj.ExBlock.Channels.name};
           obj.Channels.Selected = 1;
           obj.UI.Parent = obj;
           obj.UI.channel = 1;
           
           obj.UI.ChannelSelector = nigeLab.libs.ChannelUI(obj.UI);
           obj.Listeners = [obj.Listeners, ...
               addlistener(obj.UI.ChannelSelector,'NewChannel',...
               @obj.setChannel)];
           
           
           obj.renderData()
           
           
       end
       
       function flag = set(~,field,~)
           % This does not serve any purpose. Just to keep the channel
           % selector happy. For whatever reason was requiring this to be
           % in place
           if strcmp(field,'channel')
               flag = true;
           else
               flag = false;
           end
       end
       
       function setChannel(obj,src,evt)
            obj.Channels.Selected = src.Channel;
            renderData(obj)
       end
       
       function renderData(obj)
          
           thisBlock = obj.ExBlock;
           
           L = thisBlock.Samples;
           fs = thisBlock.SampleRate;
           MaxSamples = 10*60*fs; % 10 minutes max recording
           obj.startIdx = randi(max(1,L-MaxSamples));           
           obj.endIdx = min(L,obj.startIdx+MaxSamples);
           chanIdx = obj.Channels.Selected;
           if obj.endIdx == L
               obj.durSlider.Enable = 'off';
              obj.SliderLbl.Enable = 'off'; 
           end
           
           t = (obj.startIdx:obj.endIdx)./fs;
           obj.data = thisBlock.Channels(chanIdx).Filt(obj.startIdx:obj.endIdx);
           plot(obj.DataAx,t,obj.data);
           xlim(obj.DataAx,[t(1) min(t(1)+60,t(end))]);
           obj.DataAx.YAxis.Color = [1,1,1];obj.DataAx.XAxis.Color = [1,1,1];
           title(obj.DataAx,'Filtered Data','Color',[1 1 1]);

       end
       
       function delete(obj)
           delete(obj.UI.ChannelSelector);
           delete(obj.UI.Fig);
       end
       
       function buildGUI(obj,fig)
           % BUILDGUI  Build the graphical interface
         %
         %  fig = obj.buildGUI(); Constructs new figure and adds panels
         %
         %  fig = obj.buildGUI(fig);  Adds the panels only
         
         if nargin < 2
            obj.UI.Fig = figure(...
               'Toolbar','none',...
               'MenuBar','none',...
               'NumberTitle','off',...
               'Units','pixels',...
               'Position',[1500 200 800 700],...
               'Color',nigeLab.defaults.nigelColors('bg'),...
               'Visible','on',...
               'CloseRequestFcn',@(~,~) obj.delete);
           fig = obj.UI.Fig;
         else
            obj.UI.Fig = fig; 
         end
         
         
         obj.DataAx = axes(fig,'Units','normalized','Position',[.05 .7   .9 .25],'Box','off');
         obj.ZoomBtn = uicontrol(fig,'Style','togglebutton',...
             'String','Z',...
             'Units','normalized','Position',[.05 .96 .03 .03],'Callback',@(~,~)zoom(fig));
         jh = nigeLab.utils.findjobj(obj.ZoomBtn);
         jh.setBorderPainted(false);
         jh.setContentAreaFilled(false);
         zbtnImgPath = fullfile(matlabroot,'toolbox\matlab\appdesigner\web\release\images\figurefloatingpalette','zoomin_cursor3D.png');
         if exist(zbtnImgPath,'file')
             img = imread(zbtnImgPath);
             set(obj.ZoomBtn,'CData',img);
         end
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
         obj.SDBtn = uicontrol(obj.BtnPanel,'Style','pushbutton','String','SD',...
             'Units','normalized',...
             'Position',[.1 .1 .35 .2],...
             'Callback',@(~,~)obj.StartSD);
         
         obj.ARTBtn = uicontrol(obj.BtnPanel,'Style','pushbutton','String','ArtRej',...
             'Units','normalized',...
             'Position',[.5 .1 .35 .2],...
             'Callback',@(~,~)obj.StartArtRej);
         
         obj.SDParsPanel = uitabgroup(fig,...
            'Units','normalized',...
            'Position',[.05 .25  .65 .4]);
        
        obj.ArtRejParsPanel = uitabgroup(fig,...
            'Units','normalized',...
            'Position',[.05 .05  .65 .18]);
        
        % fill SD panel
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
                  'Callback',@(hObj,~,~)textBoxCallback(obj,hObj,['SD_' obj.SDMethods{ii}],thisParsNames{jj}));
              
              thisParLbl =  uicontrol('Style','text',...
                  'Parent',thisTab,...
                  'Units','pixels',...
                  'Position',[38 + Hoff  235 + Woff   70   18],...
                  'String',thisParsNames{jj},...
                  'HorizontalAlignment','left');
              
           end
        end
         
        
        % fill artefact rejection panel
         for ii = 1:numel(obj.ARTMethods)
           % Add all uitabs
           thisTab = uitab(obj.ArtRejParsPanel,'Title',obj.ARTMethods{ii},'Scrollable','on');
           thisPars = (obj.ExBlock.Pars.SD.(['ART_' obj.ARTMethods{ii}]));
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
                  'Position',[38 + Hoff   60 + Woff   37   18],...
                  'String',nigeLab.utils.ToString(thisPars.(thisParsNames{jj})),...
                  'Callback',@(hObj,~,~)textBoxCallback(obj,hObj,['ART_' obj.ARTMethods{ii}],thisParsNames{jj}));
              
              thisParLbl =  uicontrol('Style','text',...
                  'Parent',thisTab,...
                  'Units','pixels',...
                  'Position',[38 + Hoff  78 + Woff   70   18],...
                  'String',thisParsNames{jj},...
                  'HorizontalAlignment','left');
              
           end
         end
        
         
       end
       
       function textBoxCallback(obj,hObj,MethodName,ParName)
           val = get(hObj,'String');
           thiPar = obj.ExBlock.Pars.SD.(MethodName).(ParName);
           
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
           
           obj.Pars.(MethodName).(ParName) = convertedVal;
       end
       
       function changeDataLim(obj,hobj)
           val = hobj.Value;
           obj.DataAx.XLim(2) = obj.DataAx.XLim(1) + val*60;
           obj.SliderLbl.String = sprintf('%.2f Min',val);
       end
       
       function StartSD(obj)
           if isempty(obj.artRejData)
               obj.StartArtRej;
           end

           AlgName = obj.SDParsPanel.SelectedTab.Title;
           SDFun = ['SD_' AlgName];
           SDPars = obj.Pars.(SDFun);
           SDPars.fs = obj.ExBlock.SampleRate;
           SDargsout = obj.ExBlock.testSD(SDFun,obj.artRejData,SDPars);
           
           tIdx        = SDargsout{1};
           peak2peak = SDargsout{2};
           peakAmpl  = SDargsout{3};
           peakWidth = SDargsout{4};
           
            plotSpikes(obj,tIdx,peakAmpl,peakWidth)
       end
       
       function StartArtRej(obj)
           AlgName = obj.ArtRejParsPanel.SelectedTab.Title;

           ArtFun = ['ART_' AlgName];
           ArtPars = obj.Pars.(ArtFun);
           ArtPars.fs =  obj.ExBlock.SampleRate;
           Artargsout = obj.ExBlock.testSD(ArtFun,obj.data,ArtPars);
           obj.artRejData = Artargsout{1};
           artifact = Artargsout{2};
           
           plotArt(obj,artifact)
       end
       
       function plotArt(obj,art)
           hold(obj.DataAx,'on');
           fs = obj.ExBlock.SampleRate;
           t = (obj.startIdx:obj.endIdx)./fs;
           delete([obj.artPlot,obj.spkPlot]);
           cla(obj.SpikeAx);
           obj.artPlot = plot(obj.DataAx,t(art),obj.data(art),'og');
           legend(obj.DataAx,{'Data','Artifacts'});
       end
       
       function plotSpikes(obj,tIdx,peakAmpl,peakWidth)
           fs = obj.ExBlock.SampleRate;
           t = (obj.startIdx:obj.endIdx)./fs;
           
           WindowPreSamples =  obj.Pars.WPre * 1e-3 * fs;
           WindowPostSamples =  obj.Pars.WPost * 1e-3 * fs;
           out_of_record = tIdx <= WindowPreSamples+1 | tIdx >= length(obj.data) - WindowPostSamples - 2;
          
           peakAmpl(out_of_record) = [];
           peakWidth(out_of_record) = [];
           tIdx(out_of_record) = [];
           
           
           hold(obj.DataAx,'on');
           delete(obj.spkPlot);
           obj.spkPlot = plot(obj.DataAx,t(tIdx),peakAmpl,'*r');
           legend(obj.DataAx,{'Data','Artifacts','Spikes'});
           % BUILD SPIKE SNIPPET ARRAY AND PEAK_TRAIN
           tIdx = tIdx(:); % make sure it's vertical
           cla(obj.SpikeAx);
           if (any(tIdx)) % If there are spikes in the current signal
               snippetIdx = (-WindowPreSamples : WindowPostSamples) + tIdx;
               spikes = obj.data(snippetIdx);
               plot(obj.SpikeAx,(-WindowPreSamples : WindowPostSamples)./fs,spikes);
               obj.SpikeAx.YAxis.Color = [1,1,1];obj.SpikeAx.XAxis.Color = [1,1,1];
           end
           
           title(obj.SpikeAx,'Spikes','Color',[1 1 1]);

       end
       
   end
   
   
end