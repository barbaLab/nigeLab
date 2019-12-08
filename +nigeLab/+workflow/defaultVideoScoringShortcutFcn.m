function defaultVideoScoringShortcutFcn(obj,idx,val)
% DEFAULTVIDEOSCORINGSHORTCUTFCN  Handles shortcuts during video scoring
%
%  behaviorInfo.ValueShortcutFcn =
%     @nigeLab.workflow.defaultVideoScoringShortcutFcn;
%
%  Inputs:
%  obj  --  nigeLab.libs.behaviorInfo class object associated with video
%           scoring
%  idx  --  Index into the variable name that is to be updated. For
%              example, if defaults.Event.VarsToScore = {'Reach','Grasp'},
%              then idx == 1 would update 'Reach'.
%  val  --  Value to update that variable with.
%  
% Rationale for function handle in +workflow:
% Allows user to set specific parsing of shortcuts for video scoring
% heuristics. For example, if there is no 'Grasp', then the trial cannot be
% a successful one, if videos being scored are for the pellet retrieval
% task. Since this type of function might be designed on much more of an
% 'ad hoc' basis, I wanted to remove it from 'utils' and keep it in
% 'workflow' instead.
%
%  Description of behavior
%  -----------------------
%  For this function, the default behavior is:
%       obj.varVal(idx) = val;
%       obj.idx = idx;
%       notify(obj,'update');
%
%  If 'Grasp', 'Pellets', or 'PelletPresent' are parsed based on 'idx' then
%     a different behavior is performed as a shortcut, depending on what
%     the value ('val') is.

%%
switch obj.varName{idx}
   case 'Grasp'
      obj.varVal(idx) = val;
      obj.idx = idx;
      if obj.verbose
         s = nigeLab.utils.getNigeLink(...
            'nigeLab.workflow.defaultVideoScoringShortcutFcn',44);
         fprintf(1,'-->\tupdate event issued: %s\n',s);
      end
      notify(obj,'update');
      if isinf(val) % Must be unsuccessful if no grasp
         idx = getVarIdx(obj,'Outcome');
         
         if ~isempty(idx)
            obj.idx = idx;
            obj.varVal(idx) = 0;
            if obj.verbose
               s = nigeLab.utils.getNigeLink(...
                  'nigeLab.workflow.defaultVideoScoringShortcutFcn',56);
               fprintf(1,'-->\tcountIsZero event issued: %s\n',s);
            end
            notify(obj,'countIsZero');
         end
         
         % Check that support not entered; if not, default it to
         % inf at this point.
         idx = getVarIdx(obj,'Support');
         if ~isempty(idx)
            if isnan(obj.varVal(idx))
               obj.varVal(idx) = inf;
               obj.idx = idx;
               if obj.verbose
                  s = nigeLab.utils.getNigeLink(...
                     'nigeLab.workflow.defaultVideoScoringShortcutFcn',71);
                  fprintf(1,'-->\tupdate event issued: %s\n',s);
               end
               notify(obj,'update');
            end
         end
      end
   case 'Pellets' % if 0 pellets are present, must be no pellet
      obj.misc.PrevPelletValue = val; % Update log of previous pellet
      if val==0
         idx = getVarIdx(obj,{'Pellets','PelletPresent','Outcome'});
         if ~isempty(idx)
            obj.idx = idx;
            for ii = 1:numel(idx)
               obj.varVal(idx(ii)) = 0;
            end
            if obj.verbose
               s = nigeLab.utils.getNigeLink(...
                  'nigeLab.workflow.defaultVideoScoringShortcutFcn',89);
               fprintf(1,'-->\tcountIsZero event issued: %s\n',s);
            end
            notify(obj,'countIsZero');
         end
      else
         obj.varVal(idx) = val;
         obj.idx = idx;
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.workflow.defaultVideoScoringShortcutFcn',99);
            fprintf(1,'-->\tupdate event issued: %s\n',s);
         end
         notify(obj,'update');
      end
   case 'PelletPresent' % if pellet presence
      if val==0 % if not present, must be unsuccessful
         idx = getVarIdx(obj,{'PelletPresent','Outcome'});
         if ~isempty(idx)
            obj.idx = idx;
            for ii = 1:numel(idx)
               obj.varVal(idx(ii)) = 0;
            end
            if obj.verbose
               s = nigeLab.utils.getNigeLink(...
                  'nigeLab.workflow.defaultVideoScoringShortcutFcn',114);
               fprintf(1,'-->\tcountIsZero event issued: %s\n',s);
            end
            notify(obj,'countIsZero');
         end
         
      else
         obj.varVal(idx) = val;
         obj.idx = idx;
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.workflow.defaultVideoScoringShortcutFcn',125);
            fprintf(1,'-->\tupdate event issued: %s\n',s);
         end
         notify(obj,'update');
      end
      
      % should also check what previous trial pellet count was
      % and set this one to that if possible
      idx = getVarIdx(obj,'Pellets');
      
      if ~isempty(idx)
         if (isnan(obj.varVal(idx)) || isinf(obj.varVal(idx))) ...
               && (obj.cur>1)
            obj.idx = idx;
            % If everything works, get previous value:
            obj.varVal(idx) = obj.misc.PrevPelletValue;
            if obj.verbose
               s = nigeLab.utils.getNigeLink(...
                  'nigeLab.workflow.defaultVideoScoringShortcutFcn',143);
               fprintf(1,'-->\tupdate event issued: %s\n',s);
            end
            notify(obj,'update');
         end
      end
   otherwise
      % Default behavior is to set the value and notify of update
      obj.varVal(idx) = val;
      obj.idx = idx;
      if obj.verbose
         s = nigeLab.utils.getNigeLink(...
            'nigeLab.workflow.defaultVideoScoringShortcutFcn',155);
         fprintf(1,'-->\tupdate event issued: %s\n',s);
      end
      notify(obj,'update');
end

end