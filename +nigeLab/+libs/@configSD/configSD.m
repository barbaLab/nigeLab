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
       ResampleBtn
       ExportBtn
       
       AllTextBoxes
       
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
           
           
           obj.sampleData()
           
           
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
            sampleData(obj);
            renderData(obj)
       end
       
       function renderData(obj)
          cla(obj.DataAx,'reset');
          cla(obj.SpikeAx,'reset');
          
           thisBlock = obj.ExBlock;
           fs = thisBlock.SampleRate;
           t = (obj.startIdx:obj.endIdx)./fs;

           
           plot(obj.DataAx,t,obj.data);
           xlim(obj.DataAx,[t(1) min(t(1)+60,t(end))]);
           obj.DataAx.YAxis.Color = [1,1,1];obj.DataAx.XAxis.Color = [1,1,1];
           title(obj.DataAx,sprintf('Filtered Data, %.2f minutes',numel(t)./fs./60),'Color',[1 1 1]);

       end
       
       function sampleData(obj)
           
           waitFig = plotWaitFigure(obj,'Sampling data...');
           lockedObjs = obj.lockUnlockGui([],'off');
           
           thisBlock = obj.ExBlock;
           obj.data = [];
           obj.artRejData = [];
           
           L = thisBlock.Samples;
           fs = thisBlock.SampleRate;
           Samples = floor(obj.durSlider.Value*60*fs); % length of ther selected recording
           obj.startIdx = randi(max(1,L-Samples));
           obj.endIdx = min(L,obj.startIdx+Samples);
           chanIdx = obj.Channels.Selected;
           if L<60*fs
               % removing durSlider from the list of objs to reenable
               lockedObjs(lockedObjs == obj.durSlider) = [];
               lockedObjs(lockedObjs == obj.SliderLbl) = [];
               obj.durSlider.Enable = 'off';
               obj.SliderLbl.Enable = 'off';
               obj.SliderLbl.String = 'less then 1min data.';
           end
           
           isCar = thisBlock.getStatus('CAR');
           isFilt = thisBlock.getStatus('Filt');
           if isCar
               obj.data = thisBlock.Channels(chanIdx).CAR(obj.startIdx:obj.endIdx);
           elseif isFilt
               obj.data = thisBlock.Channels(chanIdx).Filt(obj.startIdx:obj.endIdx);
           else
               error('Niether Filt nor Car detected.%cYou need to have ate least your signal filtered for spike detection!',newline);
           end
           renderData(obj);
           
           obj.lockUnlockGui(lockedObjs,'on');
           delete(waitFig);
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
             'Callback',@(hObj,~,~)set(obj.SliderLbl,'String',sprintf('%.2f Min',hObj.Value)));
         obj.ResampleBtn = uicontrol(obj.BtnPanel,'Style','pushbutton','String','Resample',...
             'Units','normalized',...
             'Position',[.5 .5 .35 .2],...
             'Callback',@(~,~)obj.sampleData());
         
         
         obj.SDBtn = uicontrol(obj.BtnPanel,'Style','pushbutton','String','SD',...
             'Units','normalized',...
             'Position',[.1 .3 .35 .2],...
             'Callback',@(~,~)obj.StartSD);
         
         obj.ARTBtn = uicontrol(obj.BtnPanel,'Style','pushbutton','String','ArtRej',...
             'Units','normalized',...
             'Position',[.5 .3 .35 .2],...
             'Callback',@(~,~)obj.StartArtRej);
         
         obj.ExportBtn = uicontrol(obj.BtnPanel,'Style','pushbutton','String','Export',...
             'Units','normalized',...
             'Position',[.1 .05 .75 .2],...
             'Callback',@(~,~)obj.ExportPars);
         
         obj.SDParsPanel = uitabgroup(fig,...
            'Units','normalized',...
            'Position',[.05 .25  .65 .4]);
        
        obj.ArtRejParsPanel = uitabgroup(fig,...
            'Units','normalized',...
            'Position',[.05 .05  .65 .18]);
        
        % fill SD panel
        for ii = 1:numel(obj.SDMethods)
           % Add all uitabs
           thisTab = uitab(obj.SDParsPanel,'Title',obj.SDMethods{ii});
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
         obj.SDParsPanel.SelectedTab = findobj(obj.SDParsPanel,...
             'Title',obj.Pars.SDMethodName);
        
        % fill artefact rejection panel
         for ii = 1:numel(obj.ARTMethods)
           % Add all uitabs
           thisTab = uitab(obj.ArtRejParsPanel,'Title',obj.ARTMethods{ii});
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
         obj.ArtRejParsPanel.SelectedTab = findobj(obj.ArtRejParsPanel,...
             'Title',obj.Pars.ArtefactRejMethodName);
         
       end
       
       function ExportPars(obj)
           SDAlgName = obj.SDParsPanel.SelectedTab.Title;
           ArtRejAlgName = obj.ArtRejParsPanel.SelectedTab.Title;

          obj.Pars.ArtefactRejMethodName = ArtRejAlgName;
          obj.Pars.SDMethodName = SDAlgName;

           obj.ExBlock.Pars.SD = obj.Pars;
           obj.ExBlock.saveParams;
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
       
       function AllObjs = lockUnlockGui(obj,objs,status)
           if nargin<2
               % no additional inputs. Looks for all objs and toggles the
               % status
               AllObjs = findobj(obj.UI.Fig,'type','uicontrol');
               lockUnlockGui(obj,AllObjs);
           
           elseif nargin <3
               % All inputs are provided. Sets the enabled property of the
               % objs provided to status 
               onObjs = findobj(objs,'type','uicontrol','enable','on');
               offObjs = findobj(objs,'type','uicontrol','enable','off');
               lockUnlockGui(obj,onObjs,'off');
               lockUnlockGui(obj,offObjs,'on');
                AllObjs = [onObjs(:);offObjs(:)];
           elseif nargin <4 && isempty(objs)
               % Second input is []. Looks for all objs with enable =
               % ~status and sets the status to status. 
               % Ex obj.lockUnlockGui([],'on') enables all disabled controls
               switch status
                   case {true,'on'}
                       Currentstatus = 'off';
                   case {false,'off'}
                       Currentstatus = 'on';
               end
               AllObjs = findobj(obj.UI.Fig,'type','uicontrol','enable',Currentstatus);
               lockUnlockGui(obj,AllObjs,status); 
           else
               switch status
                   case {true,'on'}
                       status = 'on';
                   case {false,'off'}
                       status = 'off';
               end
               set(objs,'Enable',status);
           end
       end
       
       function waitFig = plotWaitFigure(obj,message)
           waitFig = figure('Units','pixels','MenuBar','none','ToolBar','none','NumberTitle','off','CloseRequestFcn',[]);
           waitFig.Position = [obj.UI.Fig.Position(1:2) + obj.UI.Fig.Position(3:4)./2 272 40];
           waitFig.Name = 'Wait! I''m thinking...';
           uicontrol(waitFig,'Style','text','Units','normalized','String',message,'Position',[.05 .05 .9 .9]);
           drawnow;
           figAlwaysOnTop(obj,waitFig,true)
       end
       
       function StartSD(obj)
           if isempty(obj.artRejData)
               obj.StartArtRej;
           end

           waitFig = plotWaitFigure(obj,'Detecting spikes...');
           lockedObjs = obj.lockUnlockGui([],'off');
           
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
            
            obj.lockUnlockGui(lockedObjs,'on');
           delete(waitFig);
       end
       
       function StartArtRej(obj)
           waitFig = plotWaitFigure(obj,'Detecting artefacts...');
           lockedObjs = obj.lockUnlockGui([],'off');
           
           AlgName = obj.ArtRejParsPanel.SelectedTab.Title;

           ArtFun = ['ART_' AlgName];
           ArtPars = obj.Pars.(ArtFun);
           ArtPars.fs =  obj.ExBlock.SampleRate;
           Artargsout = obj.ExBlock.testSD(ArtFun,obj.data,ArtPars);
           obj.artRejData = Artargsout{1};
           artifact = Artargsout{2};
           
           plotArt(obj,artifact)
           
           
           obj.lockUnlockGui(lockedObjs,'on');
           delete(waitFig);
       end
       
       function plotArt(obj,art)
           hold(obj.DataAx,'on');
           fs = obj.ExBlock.SampleRate;
           t = (obj.startIdx:obj.endIdx)./fs;
           delete([obj.artPlot,obj.spkPlot]);
           cla(obj.SpikeAx);
           dat = obj.data;
           dat(setdiff(1:length(t),art)) = nan;
           obj.artPlot = line(obj.DataAx,t,dat,'LineStyle','-','LineWidth',2,'Color','g');
           legend(obj.DataAx,{'Data','Artifacts'});
       end
       
       function plotSpikes(obj,tIdx,peakAmpl,peakWidth)
           fs = obj.ExBlock.SampleRate;
           t = (obj.startIdx:obj.endIdx)./fs;
           
           WindowPreSamples =  floor(obj.Pars.WPre * 1e-3 * fs);
           WindowPostSamples =  floor(obj.Pars.WPost * 1e-3 * fs);
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
           cla(obj.SpikeAx,'reset');
           if (any(tIdx)) % If there are spikes in the current signal
               snippetIdx = (-WindowPreSamples : WindowPostSamples) + tIdx;
               spikes = obj.data(snippetIdx);
               
               nBins = 300;
               y_edge = linspace(min(spikes(:)),max(spikes(:))*1.2,nBins);
               C = zeros(nBins-1,size(spikes,2));
               A = zeros(nBins,size(spikes,2));
               for ii = 1:size(spikes,2)
                   [C(:,ii),A(:,ii)] = histcounts(spikes(:,ii),y_edge);
               end
               im = imagesc(obj.SpikeAx,(-WindowPreSamples : WindowPostSamples)./fs,y_edge(1:end-1) ,(C./size(spikes,1))); 
               colormap(obj.SpikeAx,'hot');
               box(obj.SpikeAx,'off');
               
%                plot(obj.SpikeAx,(-WindowPreSamples : WindowPostSamples)./fs,spikes);
               obj.SpikeAx.YAxis.Color = [1,1,1];obj.SpikeAx.XAxis.Color = [1,1,1];obj.SpikeAx.YDir = 'normal';
           else
               spikes = [];
           end
           
           title(obj.SpikeAx,sprintf('%d spikes',size(spikes,1)),'Color',[1 1 1]);

       end
       
       function figAlwaysOnTop(obj,fig,mode)
           if nargin < 2
               mode = false;
           end
           % toggle figure alway on top. Has to be changed before
         % the visibility property
         %                     drawnow;
         warningTag = 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame';
         warning('off',warningTag);
         
         jFrame = get(handle(fig),'JavaFrame');
         jFrame_fHGxClient = jFrame.fHG2Client;
         jFrame_fHGxClientW=jFrame_fHGxClient.getWindow;
         tt = tic;
         while(isempty(jFrame_fHGxClientW))
             if toc(tt) > 5
                 % this is not critical, no need to lock everythong here if
                 % it's not working
                 warning('on',warningTag);
                 return;
             end
            jFrame_fHGxClientW=jFrame_fHGxClient.getWindow;
         end

         jFrame_fHGxClientW.setAlwaysOnTop(mode);
         warning('on',warningTag);
       end
       
   end
   
   
end