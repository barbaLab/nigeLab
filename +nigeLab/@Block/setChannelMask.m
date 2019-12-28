function flag = setChannelMask(blockObj,includedChannelIndices)
%SETCHANNELMASK    Set included channels to use for subsequent analyses
%
%  flag = blockObj.SETCHANNELMASK;      % sets from user interface
%  flag = blockObj.SETCHANNELMASK(includedChannelIndices); % no UI
%
%  inputs --
%  --> includedChannelIndices : (double) indexing array for .Channels, or
%                               (logical) mask of same size as .Channels,
%                                         where TRUE denotes that the
%                                         .Channels element should be kept
%                                         for further processing.
%
%     --> If blockObj is an array, then includedChannelIndices may be
%           specified as a cell array of indexing vectors, which must 
%           contain one cell per block in the array.
%
%  Sets blockObj.Mask property, which is an indexing array (double) that
%  specifies the indices of the blockObj.Channels struct array that are to
%  be included for subsequent analyses 
%     (e.g. blockObj.Channels(blockObj.Mask).(fieldOfInterest) ... would
%           return only the "good" channels for that recording).

%% PARSE INPUT
if nargin < 2
   includedChannelIndices = nan;
end

if numel(blockObj) > 1
   flag = true;
   if iscell(includedChannelIndices)
      if numel(blockObj) ~= numel(includedChannelIndices)
         error(['nigeLab:' mfilename ':BlockArrayInputMismatch'],...
            ['%g elements in blockObj array input, ' ...
             'but only %g elements in channel index cell array input'],...
             numel(blockObj),numel(includedChannelIndices));
      end
   end   
   for i = 1:numel(blockObj)
      if iscell(includedChannelIndices)
         flag = flag && blockObj(i).setChannelMask(includedChannelIndices{i});
      else
         flag = flag && blockObj(i).setChannelMask(includedChannelIndices);
      end
   end
   return;
else
   flag = false;
end

% If it is logical, make sure the number of logical elements makes sense
if islogical(includedChannelIndices)
   if numel(includedChannelIndices) ~= numel(blockObj.Channels)
      if numel(includedChannelIndices) ~= numel(blockObj.Mask)
         error(['nigeLab:' mfilename ':BadMaskIndexArray2'],...
            ['Logical indexing mask vector has %g elements, ' ...
             'but should have %g elements (blockObj.Channels) or ' ...
             '%g elements (blockObj.Mask) instead.'],...
             numel(includedChannelIndices),...
             numel(blockObj.Channels),...
             numel(blockObj.Mask));            
      else
         % Otherwise, "mask the mask"
         includedChannelIndices = blockObj.Mask(includedChannelIndices);
      end
   else
      % Convert to `double` indexing array for consistency
      vec = 1:numel(blockObj.Channels);
      includedChannelIndices = vec(includedChannelIndices);
   end
end

if ~isnan(includedChannelIndices) % Then mask was already given as input
   % Parse for errors
   if any(includedChannelIndices < 1)
      error(['nigeLab:' mfilename ':BadMaskIndexArray1'],...
         'Invalid channel mask indices. Arrays must start at 1.');
   elseif any(includedChannelIndices > numel(blockObj.Channels))
      error(['nigeLab:' mfilename ':BadMaskIndexArray2'],...
         ['Invalid channel mask indices. Largest channel index is %d.\n' ...
          'blockObj.Mask is an index array to blockObj.Channels (%s)'],...
          blockObj.Name, numel(blockObj.Channels));
   end
   
   % Parse for oddities
   includedChannelIndices = unique(includedChannelIndices);
   includedChannelIndices = sort(includedChannelIndices,'ascend');
   
   % Set the channel mask
   blockObj.Mask = includedChannelIndices;
   return;
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
blockObj.Mask = find(maskVal);


waitfor(h);
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