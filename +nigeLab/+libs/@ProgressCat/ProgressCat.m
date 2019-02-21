classdef ProgressCat < handle
%% PROGRESSCAT  A visual indicator of progress on a loop.

   properties (Access = public)
      Figure
      Ax
      Im
      Label
      Function
   end
   
   properties (Access = private)
      imgStr = 'Nigel_%03g.jpg';
      nImg = 11;
      pawsInterval = 0.125;
   end
   
   methods (Access = public)
      function obj = ProgressCat(func)
         % Set properties
         obj.Function = func;
         
         % Set up progress circle
         obj.Figure = figure('Name','Interpolation Progress',...
            'MenuBar','none',...
            'NumberTitle','off',...
            'ToolBar','none',...
            'GraphicsSmoothing','off',...
            'Units','Normalized',...
            'Position',[0.4 0.4 0.2 0.3]);
         obj.Ax = axes('Parent',obj.Figure,...
            'Units','Normalized',...
            'Position',[0 0 1 1],...
            'XLim',[-1 1], ...
            'XTick',[], ...
            'YLim',[-1 1], ...
            'YTick',[],...
            'YDir','reverse',...
            'Color','k',...
            'NextPlot','add');
         obj.Label = text(-20,0,'Interpolating spikes...',...
            'FontSize',16,...
            'FontWeight','bold',...
            'FontName','Arial',...
            'Color','w');
      end
      
      function output = RunLoop(obj,N,M)
         output = nan(N,M);
         prev_prog = 0;
         cur_prog = 0;
         iCount = 0;
         for ii = 1:N
            output(ii,:) = obj.Function(ii);
            cur_prog = floor(ii/N*100);
            if cur_prog == (prev_prog+5)
               figure(obj.Figure); % Ensure focus on this circle fig
               str = sprintf(obj.imgStr,rem(iCount,obj.nImg));
               I = imread(str);
               obj.Im = imagesc(obj.Ax,[-1 1],[-1 1],I);               
               drawnow;
               pause(obj.pawsInterval);
               iCount = iCount + 1;
               prev_prog = cur_prog;
            end
         end
         delete(obj.Label);
         delete(obj.Ax);
         delete(obj.Im);
         delete(obj.Figure);
         delete(obj);
      end
   end
   
end