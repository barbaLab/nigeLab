classdef Events < handle
   %EVENTS  Handle class for nigeLab.Block property 'Events'
   
   properties (Access = public)
      Parent
   end
   
   methods (Access = public)
      % Class constructor for EVENTS class
      function obj = Events(blockObj)
         % EVENTS  Handle class for nigeLab.Block property 'Events'
         %
         %  obj = nigeLab.libs.Events(blockObj);
         %
         %  e.g.
         %  blockObj = nigeLab.Block;
         %  blockObj.Events = nigeLab.libs.Events(blockObj);
         %
         %  --> Initializes Events for Block blockObj. If blockObj should
         %      be passed as a scalar, not an array, since this is a handle
         %      class.
         
         %% Check input
         if ~isa(blockObj,'nigeLab.Block')
            error('blockObj must be a member of nigeLab.Block class.');
         end
         
         if ~isscalar(blockObj)
            error('blockObj must be scalar.');
         end
         
         %%
         obj.Parent = blockObj;
         
      end
   end
   
   % "REFERENCE" methods for quick indexing from "Header" and "Trial" data
   methods (Access = public)
      % Quick reference to all varType == 1 members (timestamp scoring)
      function ts = EventTimes(obj,trialIdx,getsetmode)
         % EVENTTIMES  Scoring that contains timestamp data
         %
         %  ts = obj.EventTimes; Returns all Event Times (Reach Grasp etc)
         %  ts = obj.EventTimes(trialIdx); Returns indexed Event Times
         %  obj.EventTimes(__,'set');  Updates diskfile data for current
         %                             trial Event Times (agnostic to value
         %                             given for trialIdx).
         
         if nargin < 3
            getsetmode = 'get';
         end
         
         v = obj.varName(obj.varType == 1);
         switch lower(getsetmode)
            case 'get'
               if nargin > 1
                  ts = nan(1,numel(v));
                  for iV = 1:numel(v)
                     t = getEventData(obj.Block,obj.fieldName,'ts',v{iV});
                     ts(iV) = t(trialIdx);
                  end
               else
                  ts = nan(numel(obj.Trials),numel(v));
                  for iV = 1:numel(v)
                     ts(:,iV) = getEventData(obj.Block,obj.fieldName,'ts',v{iV});
                  end
               end
               return;
            case 'set'
               val = obj.varVal(obj.varType == 1);
               for iV = 1:numel(v)
                  setEventData(obj.Block,obj.fieldName,'ts',v{iV},val(iV),obj.cur);
               end
               return;
            otherwise
               error('Invalid getsetmode value: %s',getsetmode);
         end
         
      end
      
      % Quick reference to metadata header
      function h = Header(obj)
         % HEADER  Contains metadata variable types
         
         h = getEventData(obj.Block,obj.fieldName,'snippet','Header');
         
      end
      
      % Quick reference to scored metadata
      function data = Meta(obj,trialIdx,getsetmode)
         % META  Returns Trial metadata. Variables are defined by Header.
         %
         %  data = obj.Meta; Returns all trial metadata for all trials
         %  data = obj.Meta(trialIdx); Returns specific trial metadata
         %  obj.Meta(__,'set');        Update disk file with current
         %                              values for this trial's metadata
         %                              (agnostic to trialIdx value)
         
         if nargin < 3
            getsetmode = 'get';
         end
         
         switch lower(getsetmode)
            case 'get'
               data = getEventData(obj.Block,obj.fieldName,'snippet','Trial');
               if nargin > 1
                  data = data(trialIdx,:);
               end
               return;
            case 'set'
               val = obj.varVal(obj.varType > 1);
               setEventData(obj.Block,obj.fieldName,'meta','Trial',val,obj.cur);
            otherwise
               error('Invalid getsetmode value: %s',getsetmode);
         end
         
         
         
      end
      
      % Quick reference for video offset from header
      function offset = Offset(obj)
         % OFFSET  Gets the video offset (seconds) for each video
         
         offset = getEventData(obj.Block,obj.fieldName,'ts','Header');
      end
      
      % Quick reference for Outcome
      function out = Outcome(obj,trialIdx)
         % OUTCOME  Returns false for unsuccessful, true for successful
         %           pellet retrievals.
         %
         %  out = obj.Outcome; Returns all trial outcomes
         %  out = obj.Outcome(trialIdx); Returns indexed trial outcomes
         
         vName = obj.varName(obj.varType > 1);
         
         if isempty(obj.outcomeName)
            out = true(obj.N,1);
            return;
         end
         
         iOut = strcmpi(vName,obj.outcomeName);
         
         out = getEventData(obj.Block,obj.fieldName,'snippet','Trial');
         if nargin > 1
            out = logical(out(trialIdx,iOut));
         else
            out = logical(out(:,iOut));
         end
      end
      
      % Quick reference to putative Trial times
      function ts = Trial(obj,trialIdx,val)
         % TRIAL  Returns column vector of putative trial times (seconds)
         %
         %  ts = obj.Trial; Returns all values of Trial
         %  ts = obj.Trial(trialIdx); Returns indexed values of Trial
         %  obj.Trial(trialIdx,val);  Sets indexed values of Trial
         
         if nargin < 3
            ts = getEventData(obj.Block,obj.fieldName,'ts','Trial');
            if nargin > 1
               ts = ts(trialIdx);
            end
         else
            if nargout > 0
               error('Trying to get and set at the same time?');
            end
            setEventData(obj.Block,obj.fieldName,'ts','Trial',val,trialIdx);
         end
      end
      
      % Quick reference to Trial mask
      function mask = TrialMask(obj)
         % TRIALMASK Returns column vector of zero (masked) or one
         %     (unmasked) for each putative Trial
         %
         % mask = obj.TrialMask;
         
         mask = getEventData(obj.Block,obj.fieldName,'mask','Trial');
         mask = logical(mask);
      end
   end
   
end

