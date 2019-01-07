function CRC_SwitchCluster(src,~,obj)
%% CRC_SWITCHCLUSTER  Callback to switch the cluster of a given axes.

% Get current channel
ch = obj.Data.UI.ch;

% Make sure we're referring to the axes
if isa(gco,'matlab.graphics.primitive.Image')
   p = src.Parent;
else
   p = src;
end

% Set this as being the focused object for other functions
obj.HasFocus = p;

% Set cases for LEFT ('normal') vs. RIGHT / CTRL-CLICK ('alt') vs.
% SHIFT-CLICK ('extend')
switch get(gcf,'SelectionType')
   case 'normal'
      % Track cluster assignment changes
      if abs(p.UserData(1) - obj.Data.UI.cl) > eps
         obj.Data.cl.sel.cur{ch,obj.Data.UI.cl} = ...
            sort([obj.Data.cl.sel.cur{ch,obj.Data.UI.cl}; ...
                  obj.Data.cl.sel.cur{ch,p.UserData(1)}],'ascend');
         obj.Data.cl.sel.cur{ch,p.UserData(1)} = [];
         
      end
      % Update all children of this axis
      
      set(gcf,'UserData','normal');
   case 'alt'
      % Only allow if a different cluster is selected
      if abs(obj.Data.UI.cl-p.UserData(1))>0 
         set(obj.Figure,'Pointer','circle');
         snipped_region = imfreehand(p);
         pos = getPosition(snipped_region);
         delete(snipped_region);
         
         [px,py] = meshgrid(obj.SpikeImage.X,...
            obj.SpikeImage.Y{p.UserData(1)});
         cx = pos(:,1);
         cy = pos(:,2);

         % Excellent mex version of InPolygon from Guillaume Jacquenot:
         [IN,ON] = InPolygon(px,py,cx,cy);
         pts = IN | ON;
         set(obj.Figure,'Pointer','watch');
         % Match from SpikeImage Assignments
         start = find(sum(pts,1),1,'first'); % Skip "empty" start
         last = find(sum(pts,1),1,'last'); % Skip "empty" end
         
         imove = [];
         
         for ii = start:last
            avec = obj.SpikeImage.Assignments{p.UserData(1)}(:,ii);
            fvec = find(pts(:,ii));
            fvec = repmat(fvec.',numel(avec),1);
            imove = [imove; find(any(abs(avec-fvec)<eps,2))]; %#ok<AGROW>
         end
         
         imove = unique(imove);
         
         obj.Data.cl.sel.cur{ch,obj.Data.UI.cl} = sort([...
            obj.Data.cl.sel.cur{ch,obj.Data.UI.cl};...
            obj.Data.cl.sel.cur{ch,p.UserData(1)}(imove)],...
            'ascend');
         
         obj.Data.cl.sel.cur{ch,p.UserData(1)} = setdiff(...
            obj.Data.cl.sel.cur{ch,p.UserData(1)},...
            obj.Data.cl.sel.cur{ch,p.UserData(1)}(imove));    
         set(gcf,'UserData','alt');
         set(obj.Figure,'Pointer','arrow');
      end
   case 'extend'
      % Only allow if NOT the OUT cluster
      if p.UserData > 1
         set(obj.Figure,'Pointer','cross');
         snipped_region = imfreehand(p);
         pos = getPosition(snipped_region);
         delete(snipped_region);
         
         [px,py] = meshgrid(obj.SpikeImage.X,...
            obj.SpikeImage.Y{p.UserData});
         cx = pos(:,1);
         cy = pos(:,2);

         % Excellent mex version of InPolygon from Guillaume Jacquenot:
         [IN,ON] = InPolygon(px,py,cx,cy);
         pts = IN | ON;
         
         set(obj.Figure,'Pointer','watch');
         
         % Match from SpikeImage Assignments
         start = find(sum(pts,1),1,'first'); % Skip "empty" start
         last = find(sum(pts,1),1,'last'); % Skip "empty" end
         
         imove = [];
         
         for ii = start:last
            avec = obj.SpikeImage.Assignments{p.UserData(1)}(:,ii);
            fvec = find(pts(:,ii));
            fvec = repmat(fvec.',numel(avec),1);
            imove = [imove; find(any(abs(avec-fvec)<eps,2))]; %#ok<AGROW>
         end
         
         imove = unique(imove);
         
         obj.Data.cl.sel.cur{ch,1} = sort([...
            obj.Data.cl.sel.cur{ch,1};...
            obj.Data.cl.sel.cur{ch,p.UserData(1)}(imove)],...
            'ascend');
         
         obj.Data.cl.sel.cur{ch,p.UserData(1)} = setdiff(...
            obj.Data.cl.sel.cur{ch,p.UserData(1)},...
            obj.Data.cl.sel.cur{ch,p.UserData(1)}(imove));    
         set(gcf,'UserData','extend');
         set(obj.Figure,'Pointer','arrow');
      end  
      
   otherwise
      return;   
end

% Update tracked assignments and features
CRC_UpdateClusterAssignments(obj);
CRC_PlotFeatures(obj);

% If debugging, update obj.Data in base workspace
if obj.Data.DEBUG
   handles = obj.Data;
   CRC_mtb(handles);
end
        
end