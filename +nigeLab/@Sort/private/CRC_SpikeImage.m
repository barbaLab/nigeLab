classdef CRC_SpikeImage < handle
%% CRC_SPIKEIMAGE  Class to quickly show spikes w/ imagesc instead of plot
   properties (Access = public)
      Assignments
      Clusters
      C
      X
      Y
      Parent
      CMap
      Spikes
   end
   
   properties (Access = private)
      XPoints = 400;    % Number of points for X resolution
      YPoints = 401;    % Number of points for Y resolution
      T = 1.2;          % Approx. time (milliseconds) of waveform
   end

   
   methods (Access = public)
      function obj = CRC_SpikeImage(parent)
      %% CRC_SPIKEIMAGE Quickly aggregates spikes into one image object.
         % Set this channel's parent
         obj.Parent = parent;
         ch = parent.Data.UI.ch;
         
         % Load this channel's spikes
         in=load(parent.Data.spk.fname{ch},'spikes');
         
         % Channel and cluster info
         clu_list = parent.Data.cl.num.assign.cur{ch};
         
         % Interpolate spikes
         obj.Spikes = CRC_InterpolateSpikes(obj,in);

         % Set Colormap for this image
         cm = load('CRC_Colormap.mat','ColorMap');
         obj.CMap = struct;
         obj.CMap.in = cm.ColorMap;
         obj.CMap.cur = cm.ColorMap;
         
         % Get X and Y vectors for image
         obj.X = linspace(0,obj.T,obj.XPoints);      % Milliseconds
         obj.Y = cell(parent.Data.NCLUS_MAX,1);
         for iC = 1:parent.Data.NCLUS_MAX
            obj.Y{iC} = linspace(parent.Data.SPK_YLIM(1),...
                             parent.Data.SPK_YLIM(2),...
                             obj.YPoints-1);  
         end
         
         
         % Initialize other properties
         obj.C = cell(1,parent.Data.NCLUS_MAX);
         obj.Assignments = cell(1,parent.Data.NCLUS_MAX);
         obj.Clusters = cell(1,parent.Data.NCLUS_MAX);
         fprintf(1,'->\tPlotting channel %03d spikes',ch);
         for iC = 1:parent.Data.NCLUS_MAX
            fprintf(1,'. ');
            obj.Clusters{iC} = CRC_UpdateAssignments(obj,clu_list(iC));
            [obj.C{iC}, obj.Assignments{iC}] = CRC_UpdateImage(obj,iC);
            
            % Plot image on appropriate axis
            CRC_ReDraw(obj,iC,clu_list(iC));
            set(parent.SpikePlot{iC},'XLim',[0 obj.T]);
            set(parent.SpikePlot{iC},'YLim',parent.Data.SPK_YLIM);
         end
         fprintf(1,'complete.\n\n');
      end
      
      function CRC_ReDraw(obj,PlotNum,CluNum)
         ch = obj.Parent.Data.UI.ch;
         % Re-draw specified axis
         obj.Y{PlotNum} = linspace(obj.Parent.Data.UI.spk_ylim(PlotNum,1),...
            obj.Parent.Data.UI.spk_ylim(PlotNum,2),...
            obj.YPoints-1);
         imagesc(obj.Parent.SpikePlot{PlotNum},...
            obj.X,obj.Y{PlotNum},obj.C{PlotNum},...
            'ButtonDownFcn',{@CRC_SwitchCluster,obj.Parent});
         set(obj.Parent.SpikePlot{PlotNum},'YLim',...
            obj.Parent.Data.UI.spk_ylim(PlotNum,:));
         colormap(obj.Parent.SpikePlot{PlotNum},obj.CMap.cur{CluNum})
         if PlotNum > 1
            str = sprintf('Ch %d Cluster %d        N = %d',...
               ch,CluNum-1,size(obj.Clusters{PlotNum},1));
         else
            str = sprintf('Ch %d OUT        N = %d',...
               ch,size(obj.Clusters{PlotNum},1));
         end
         set(obj.Parent.ClusterLabel{PlotNum},'String',str);
         drawnow;
      end
      
      function clus_out = CRC_UpdateAssignments(obj,clu)
         ch_cur = obj.Parent.Data.UI.ch;    
         % Dummy variable for selection indices
         A = obj.Parent.Data.cl.sel.cur{ch_cur,clu};
         if clu > 1
            A = A(obj.Parent.Data.spk.include.cur{ch_cur}(A));
         end
            
         % Make assignment
         clus_out =obj.Spikes(A,:);
      end
      
      function [im_out,assign_out] = CRC_UpdateImage(obj,clu)          
         % Get bin edges
         y = obj.Parent.Data.UI.spk_ylim(clu,:);
         y_edge = linspace(y(1),y(2),obj.YPoints); 
          
         % Pre-allocate
         im_out = zeros(obj.YPoints-1,obj.XPoints);
         assign_out = nan(size(obj.Clusters{clu},1),obj.XPoints);
         for ii = 1:obj.XPoints
            [im_out(:,ii),~,assign_out(:,ii)] = ...
               histcounts(obj.Clusters{1,clu}(:,ii),y_edge);
         end
         
         % Normalize
         im_out = im_out./max(max(im_out)); % Scale
      end
      
   end
   
   methods (Access = private)      
      function spk_out = CRC_InterpolateSpikes(obj,in)

         % Get interpolation points
         x = [1, size(in.spikes,2)];
         xv = linspace(x(1),x(2),obj.XPoints);
         
         LoopFunction = @(xin) (interp1(x(1):x(2),in.spikes(xin,:),xv));
         
         % Make ProgressCircle object
         pcirc = CRC_ProgressCircle(LoopFunction);
         
         % Run ProgressCircle Loop
         fprintf(1,'->\tInterpolating spikes...');
         spk_out = CRC_RunLoop(pcirc,size(in.spikes,1),obj.XPoints);
         fprintf(1,'complete.\n');
         
         
      end
   
   end
end