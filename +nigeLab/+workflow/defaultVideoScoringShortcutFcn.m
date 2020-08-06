function defaultVideoScoringShortcutFcn(obj,curVarIndex,updatedValue)
%DEFAULTVIDEOSCORINGSHORTCUTFCN  Handles shortcuts during video scoring
%
%  behaviorInfo.SetValueFcn =
%     @nigeLab.workflow.defaultVideoScoringShortcutFcn;
%
%  Inputs:
%  obj  --  nigeLab.libs.behaviorInfo class object associated with video
%           scoring
%  curVarIndex  --  Index into the variable name that is to be updated. For
%              example, if defaults.Event.VarsToScore = {'Reach','Grasp'},
%              then VariableIndex == 1 would update 'Reach'.
%  updatedValue  --  Value to update that variable with.
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
%       obj.VariableIndex = updatedValue;
%       obj.Value(curVarIndex) = val;
%
%  If 'Grasp', 'Pellets', or 'PelletPresent' are parsed based on 'VariableIndex' then
%     a different behavior is performed as a shortcut, depending on what
%     the value ('val') is.

switch obj.Variable{curVarIndex}
   case 'Grasp'
      obj.VariableIndex = curVarIndex;
      obj.Value(curVarIndex) = updatedValue;
      
      if isinf(updatedValue) % Must be unsuccessful if no grasp
         assignValue(obj,'Outcome',0);
         
         % Check that support not entered; if not, default it to
         % inf at this point.
         value = getValue(obj,'Support');
         if isnan(value)
            assignValue(obj,'Support',inf);
         end

      end
   case 'Pellets' % if 0 pellets are present, must be no pellet
      storeMiscData(obj,'PrevPelletValue',updatedValue); % Update log of previous pellet
      if updatedValue==0
         curVarIndex = findVariable(obj,{'Pellets','PelletPresent','Outcome'});
         if ~isempty(curVarIndex)
            obj.VariableIndex = curVarIndex;
            for ii = 1:numel(curVarIndex)
               obj.Value(curVarIndex(ii)) = 0;
            end
         end
      else
         obj.VariableIndex = curVarIndex;
         obj.Value(curVarIndex) = updatedValue;
      end
   case 'PelletPresent' % if pellet presence
      if updatedValue==0 % if not present, must be unsuccessful
         curVarIndex = findVariable(obj,{'PelletPresent','Outcome'});
         if ~isempty(curVarIndex)
            obj.VariableIndex = curVarIndex;
            for ii = 1:numel(curVarIndex)
               obj.Value(curVarIndex(ii)) = 0;
            end
         end
         
      else
         obj.VariableIndex = curVarIndex;
         obj.Value(curVarIndex) = updatedValue;
      end
      
      % should also check what previous trial pellet count was
      % and set this one to that if possible
      curVarIndex = findVariable(obj,'Pellets');
      
      if ~isempty(curVarIndex)
         if (isnan(obj.Value(curVarIndex)) || isinf(obj.Value(curVarIndex))) ...
               && (obj.TrialIndex>1)
            obj.VariableIndex = curVarIndex;
            % If everything works, get previous value:
            obj.Value(curVarIndex) = obj.misc.PrevPelletValue;
         end
      end
   case 'Outcome' % Write Outcome directly
      obj.VariableIndex = curVarIndex;
      obj.Value(curVarIndex) = updatedValue;
      obj.Outcome(obj.TrialIndex) = updatedValue;
      if ~isempty(obj.TimeAxes.BehaviorInfoObj)
         refreshGraphics(obj.TimeAxes.BehaviorInfoObj);
      end
   otherwise
      % Default behavior is to set the value and notify of update
      obj.VariableIndex = curVarIndex;
      assignValue(obj,obj.Variable(curVarIndex),updatedValue);
end

end