function flag = setChannelMask(blockObj,includedChannelIndices)
%% SETCHANNELMASK    Set included channels to use for subsequent analyses
%
%  flag = blockObj.SETCHANNELMASK;      % sets from user interface
%  flag = blockObj.SETCHANNELMASK(includedChannelIndices); % no UI
%
% By: Max Murphy  v1.0  2019/01/07  Original version (r2017a)

%% PARSE INPUT
flag = false;
if nargin > 1 % Then "includedChannelIndices" was supplied
   h = nan; % In case "waitfor" is used elsewhere
   
   % Parse for errors
   if any(includedChannelIndices < 1)
      warning('Invalid channel mask indices. Arrays must start at 1.');
      return;
   elseif any(includedChannelIndices > numel(blockObj.Channels))
      warning('Invalid channel mask indices. Largest channel index is %d.',...
         numel(blockObj.Channels));
      return;
   end
   
   % Parse for oddities
   includedChannelIndices = unique(includedChannelIndices);
   includedChannelIndices = sort(includedChannelIndices,'ascend');
   
   % Set the channel mask
   blockObj.Mask = includedChannelIndices;
else
   
   blockObj.plotWaves;
   h = blockObj.Graphics.Waves;
   [fig,n,pos] = parseWavesTickBoxLayout(blockObj.Graphics.Waves);
   b = nigeLab.utils.uiPanelizeToggleButtons(fig,n,pos,1,1);
   for ii = 1:n
      set(b{ii},'Callback',{@setMask,b,blockObj});
   end
   btn = uicontrol(fig,'Style','Pushbutton',...
      'FontName','Arial',...
      'FontSize',14,...
      'Units','Normalized',...
      'ForegroundColor',[1.0 1.0 1.0],...
      'BackgroundColor',[0.4 0.4 1.0],...
      'String','Set Mask',...
      'Position',[0.75 0.035 0.1 0.065],...
      'Callback',{@setMask,b,blockObj});
   
end

% Ensure that Mask is assigned
maskVal = zeros(1,numel(b));
for ii = 1:numel(b)
   maskVal(ii) = b{ii}.Value;
end

waitfor(h);
blockObj.Mask = find(maskVal);
flag = true;

   function [fig,n,pos] = parseWavesTickBoxLayout(fig)
      ax = get(fig,'Children');
      a = get(ax,'YAxis');
      plotLim = [min(a.TickValues) max(a.TickValues)];
      tickLim = get(ax,'YLim');
      
      
      pos = get(ax,'Position');
      
      % X-values are hard-coded
      pos(1) = pos(1) - 0.065;
      pos(3) = 0.03;
      
      % Y-values need scaling
      tickRange = diff(tickLim);
      
      plotRange = diff(plotLim)/tickRange;
      plotOffset = (plotLim(1) - tickLim(1))/tickRange;
      
      tmpY = pos(2) + plotOffset*(pos(4)-pos(2));
      tmpH = pos(2) + plotRange*(pos(4)-pos(2));
      pos(2) = tmpY;
      pos(4) = tmpH;
      
      % Return number of toggleBoxes to create
      n = numel(a.TickValues);
      
   end

   function setMask(src,~,b,blockObj)
      val = zeros(1,numel(b));
      
      % Get the axes
      iB = 1;
      while iB <= numel(blockObj.Graphics.Waves.Children)
         if isa(blockObj.Graphics.Waves.Children(iB),...
               'matlab.graphics.axis.Axes')
            ax = blockObj.Graphics.Waves.Children(iB);
            break;
         else
            iB = iB + 1;
         end
      end
      
      % Set Mask values and also turn off lines that are not included
      ch = flipud(ax.Children);
      for iB = 1:numel(b)
         val(iB) = b{iB}.Value;
         
         lineIdx = (iB-1)*2 + 1;
         textIdx = iB*2;
         
         if val(iB)==0
            ch(lineIdx).Visible = 'off';
            ch(textIdx).Visible = 'off';
         else
            ch(lineIdx).Visible = 'on';
            ch(textIdx).Visible = 'on';
         end
      end
      drawnow;
      blockObj.Mask = find(val);
      if strcmp(get(src,'Style'),'pushbutton')
         close(gcf);
      end
      
   end

end