classdef ProgressCat < handle
%% PROGRESSCAT  A visual indicator of progress on a loop.

   properties (Access = public)
      Figure
      Ax
      Im
      Function
   end
   
   properties (Access = private)
      imgData
      imgStr
      imgStrDef = 'Nigel_%03g.jpg';
      nImg = 11;
      pawsInterval = 0.125;
      progPctThresh = 2;
   end
   
   methods (Access = public)
      function obj = ProgressCat(func,varargin)
         % Parse input
         isEven = @(x) not(mod(x,2));
         if isEven(numel(varargin)) && (numel(varargin)>0)
            for iV = 1:2:numel(varargin)
               if isprop(obj,varargin{iV})
                  obj.(varargin{iV}) = varargin{iV+1};
               end
            end
         elseif numel(varargin)==1
            if isstruct(varargin{1})
               f = fieldnames(varargin{1});
               for iF = 1:numel(f)
                  if isprop(obj,f{iF})
                     obj.(f{iF}) = varargin{1}.(f{iF});
                  end
               end
            end
         end
         
         
         
         % Set properties
         obj.Function = func;
         
         % Get filenames
         pCatName = mfilename('fullpath');
         [pathStr,~,~] = fileparts(pCatName);
         fNameStr = fullfile(pathStr,obj.imgStrDef);
         obj.imgStr = strrep(fNameStr,'\','/');
         
         % Loaad image data
         I = imread(fullfile(sprintf(obj.imgStr,0)));
         obj.imgData = zeros(size(I,1),...
            size(I,2),...
            size(I,3),...
            obj.nImg,'uint8');
         for ii = 1:obj.nImg
            obj.imgData(:,:,:,ii) = ...
               imread(fullfile(sprintf(obj.imgStr,ii-1)));
         end
         
         % Set up figure, axes, and label
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
      end
      
      function output = RunLoop(obj,N,M)
         output = nan(N,M);
         prev_prog = 0;
         cur_prog = 0;
         iCount = 0;
         obj.Im = imagesc(obj.Ax,[-1 1],[-1 1],...
                  obj.imgData(:,:,1)); 
         for ii = 1:N
            output(ii,:) = obj.Function(ii);
            cur_prog = floor(ii/N*100);
            if cur_prog == (prev_prog+obj.progPctThresh)
               figure(obj.Figure); % Ensure focus on this circle fig
               
               set(obj.Im,'CData',obj.imgData(:,:,:,...
                  rem(iCount,obj.nImg)+1));
                             
               drawnow;
               pause(obj.pawsInterval);
               iCount = iCount + 1;
               prev_prog = cur_prog;
            end
         end
         delete(obj.Ax);
         delete(obj.Im);
         delete(obj.Figure);
         delete(obj);
      end
   end
   
end