classdef SpikeImage < handle
%% SPIKEIMAGE Quickly aggregates spikes into one image object.
%
%  obj = SPIKEIMAGE(spikes,fs,peak_train,class)
%
%  --------
%   INPUTS
%  --------
%   spikes     :     N x K matrix of waveform snippets for each
%                    detected candidate spike. Contains N rows,
%                    each of which corresponds K samples of a
%                    given spike waveform.
%
%      fs      :     Sampling frequency (Hz) of spike waveforms.
%
%  peak_train  :     M x 1 sparse vector that contains the total
%                    number of samples in the record, with sample
%                    indexes at which there is a candidate spike
%                    having a value equivalent ot the spike
%                    peak-to-peak amplitude.
%
%    class     :     N x 1 vector containing class label
%                    assignments for each spike waveform.
%
%  --------
%   OUTPUT
%  --------
%    obj       :     SPIKEIMAGE object that compresses the spike
%                    waveforms into flattened image objects that
%                    allows them to be visualized more easily.
%
% By: Max Murphy  v1.0  08/25/2017  Original version (R2017a)

%%
   properties (Access = public)
      Spikes % Contains all info relating to spike waves and classes
      Figure = figure('Name','SpikeImage',... % Container for graphics
                      'Units','Normalized',...
                      'MenuBar','none',...
                      'ToolBar','none',...
                      'NumberTitle','off',...
                      'Position',[0.2 0.2 0.6 0.6],...
                      'Color','k'); 
      Children % Figure subplots that contain flattened spike image
   end
   
   properties (Access = private)
      NumClus_Max = 9;
      CMap;
      YLim = [-300 150];
      XPoints = 500;    % Number of points for X resolution
      YPoints = 1001;   % Number of points for Y resolution
      T = 1.2;          % Approx. time (milliseconds) of waveform
      Defaults_File = 'SpikeImageDefaults.mat'; % Name of file with default
      PlotNames = cell(9,1);
   end

   methods (Access = public)
      function obj = SpikeImage(spikes,fs,peak_train,class,varargin)
         %% SPIKEIMAGE Quickly aggregates spikes into one image object.
         %
         %  obj = SPIKEIMAGE(spikes,fs,peak_train,class)
         %
         %  --------
         %   INPUTS
         %  --------
         %   spikes     :     N x K matrix of waveform snippets for each
         %                    detected candidate spike. Contains N rows,
         %                    each of which corresponds K samples of a
         %                    given spike waveform.
         %
         %      fs      :     Sampling frequency (Hz) of spike waveforms.
         %
         %  peak_train  :     M x 1 sparse vector that contains the total
         %                    number of samples in the record, with sample
         %                    indexes at which there is a candidate spike
         %                    having a value equivalent ot the spike
         %                    peak-to-peak amplitude.
         %
         %    class     :     N x 1 vector containing class label
         %                    assignments for each spike waveform.
         %
         %  varargin    :     (Optional) 'NAME', value input argument pairs
         %
         %  --------
         %   OUTPUT
         %  --------
         %    obj       :     SPIKEIMAGE object that compresses the spike
         %                    waveforms into flattened image objects that
         %                    allows them to be visualized more easily.
         %
         % By: Max Murphy  v1.0  08/25/2017  Original version (R2017a)
         %                 v1.1  06/13/2018  Added varargin and parsing so
         %                                   that SpikeImage can be
         %                                   modified to have an
         %                                   appropriate number of subplots
         %                                   depending on the number of
         %                                   unique clusters.
         
         %% PARSE VARARGIN
         for iV = 1:2:numel(varargin) % Can specify properties on construct
            if ~ischar(varargin{iV})
               continue
            end
            p = findprop(obj,varargin{iV});
            if isempty(p)
               continue
            end
            obj.(varargin{iV}) = varargin{iV+1};
         end
         
         %% 
         % Initialize object properties
         obj.Init(fs,peak_train);
         
         % Interpolate spikes
         obj.Interpolate(spikes);
         
         % Set spike classes
         obj.Assign(class);
         
         % Flatten spike image
         obj.Flatten;
         
         % Construct figure
         obj.Build;
      end
      
      function Build(obj)
         % Make figure or update current figure with fast spike plots.
         if ~isvalid(obj.Figure)
            obj.Figure = figure('Name','SpikeImage',...
                      'Units','Normalized',...
                      'MenuBar','none',...
                      'ToolBar','none',...
                      'NumberTitle','off',...
                      'Position',[0.2 0.2 0.6 0.6],...
                      'Color','k');
         end
         % Set figure focus
         figure(obj.Figure);
         nrows = ceil(sqrt(obj.NumClus_Max));
         ncols = ceil(obj.NumClus_Max/nrows);
         obj.Children = cell(obj.NumClus_Max,1);
         fprintf(1,'->\tPlotting spikes');
         for iC = 1:obj.NumClus_Max
            fprintf(1,'. ');
            obj.Children{iC} = subplot(nrows,ncols,iC);
            obj.Draw(iC,iC);
         end
         fprintf(1,'complete.\n\n');
      end
      
      function Draw(obj,PlotNum,CluNum)
         % Re-draw specified axis
         imagesc(obj.Children{PlotNum},...
            obj.Spikes.X,obj.Spikes.Y,obj.Spikes.C{PlotNum});
         colormap(obj.Children{PlotNum},obj.CMap{CluNum})
         set(obj.Children{PlotNum}.Title,'String',obj.PlotNames{PlotNum});
         set(obj.Children{PlotNum}.Title,'FontName','Arial');
         set(obj.Children{PlotNum}.Title,'FontSize',16);
         set(obj.Children{PlotNum}.Title,'FontWeight','bold');
         set(obj.Children{PlotNum}.Title,'Color','w');
         set(obj.Children{PlotNum},'YDir','normal');
         drawnow;
      end
      
      function Assign(obj,class)   
         % Update spikes to a given class label (numeric)
         obj.Spikes.Class = class;
         obj.Spikes.Class(class > obj.NumClus_Max) = 1;
         obj.SetPlotNames;
      end
      
      function Flatten(obj)
         % Condense all spikes into one matrix of values scaled from 0 to 1
         obj.Spikes.C = cell(obj.NumClus_Max,1);
         for iC = 1:obj.NumClus_Max
            % Get bin edges
            y_edge = linspace(obj.YLim(1),obj.YLim(2),obj.YPoints); 

            % Pre-allocate
            clus = obj.Spikes.Waves(obj.Spikes.Class==iC,:);
            im_out = zeros(obj.YPoints-1,obj.XPoints);
            assign_out = nan(size(clus,1),obj.XPoints);
            for ii = 1:obj.XPoints
               obj.Spikes.C{iC}(:,ii) = histcounts(clus(:,ii),y_edge);
            end

            % Normalize
            obj.Spikes.C{iC} = obj.Spikes.C{iC}./...
               max(max(obj.Spikes.C{iC})); 
         end
      end
      
      function set(obj,NAME,value)
         % Set 'numclus_max', 'ylim', or 'plotnames' properties and update.
         switch lower(NAME)
            case 'numclus_max'
               delete(obj.Figure.Children);
               obj.NumClus_Max = value;
               obj.Build;
            case 'ylim'
               delete(obj.Figure.Children);
               obj.YLim = value;
               obj.Spikes.Y = linspace(obj.YLim(1),...
                                       obj.YLim(2),...
                                       obj.YPoints-1);
               obj.Flatten;
               obj.Build;
            case 'plotnames'
               delete(obj.Figure.Children);
               obj.PlotNames = value;
               obj.Flatten;
               obj.Build;
            otherwise
               error('%s is not a settable property of SpikeImage.',NAME);
         end
      end
      
   end
   
   methods (Access = private)    
      function Init(obj,fs,peak_train)
         % Add sampling frequency
         obj.Spikes.fs = fs;
         obj.Spikes.peak_train = peak_train;
         
         % Set Colormap for this image
         cm = load(obj.Defaults_File,'ColorMap');
         obj.CMap = cm.ColorMap;
         obj.NumClus_Max = min(numel(obj.CMap),obj.NumClus_Max);         
         
         % Get X and Y vectors for image
         obj.Spikes.X = linspace(0,obj.T,obj.XPoints);      % Milliseconds
         obj.Spikes.Y = linspace(obj.YLim(1),obj.YLim(2),obj.YPoints-1);
      end
      
      function SetPlotNames(obj)
         for iPlot = 1:obj.NumClus_Max
            if iPlot > 1
               obj.PlotNames{iPlot} = ...
                  sprintf('Cluster %d        N = %d',...
                  iPlot-1,sum(obj.Spikes.Class==iPlot));
            else
               obj.PlotNames{iPlot} = ...
                  sprintf('OUT        N = %d',...
                  sum(obj.Spikes.Class==iPlot));
            end
         end
      end
      
      function Interpolate(obj,spikes)
         % Get interpolation points
         x = [1, size(spikes,2)];
         xv = linspace(x(1),x(2),obj.XPoints);
         
         LoopFunction = @(xin) (interp1(x(1):x(2),spikes(xin,:),xv));
         
         % Make ProgressCircle object
         pcirc = orgExp.libs.ProgressCircle(LoopFunction);
         
         % Run ProgressCircle Loop
         fprintf(1,'->\tInterpolating spikes...');
         obj.Spikes.Waves = pcirc.RunLoop(size(spikes,1),obj.XPoints);
         fprintf(1,'complete.\n');

      end
   
   end
end