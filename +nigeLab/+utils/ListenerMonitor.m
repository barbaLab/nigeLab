classdef ListenerMonitor < matlab.mixin.SetGet
   %LISTENERMONITOR  Object that listens to... listeners.
   %
   %  obj = nigeLab.utils.ListenerMonitor();
   %
   %  LISTENERMONITOR Properites
   %  Mode  --  Can be 'delete' (default), 'return', or 'disp'
   %     * Set this via the `setMode` method
   %
   %  Monitor  --  Handle to listener for `gcbo` property PostSet
   %
   %  Root  --  Root graphics object
   %
   %  gcbo  --  Dependent property that is equivalent to Root.gcbo
   %
   %  LISTENERMONITOR Methods
   %  ListenerMonitor  --  Class constructor (no input arguments)
   %
   %  setMode  --  Specify mode as 'delete', 'return', or 'disp'
   %     >> obj.setMode('delete');
   %        * Default setting
   %        * Causes any listener handle detected by gcbo to be deleted
   %
   %     >> obj.setMode('return');
   %        * Returns any listener detected by gcbo to base workspace
   %
   %     >> obj.setMode('disp');
   %        * Makes a call to `disp(obj.gcbo)` any time gcbo changes
   %           to a new value (a new listener callback detected).
   
   % % % PROPERTIES % % % % % % % % % %
   % CONSTANT,PUBLIC
   properties (Constant,Access=public)
      RETURNED_LH_NAME  char = 'lh'  % Variable name of returned listener       
   end
   
   % TRANSIENT,PUBLIC/PROTECTED
   properties (Transient,GetAccess=public,SetAccess=protected)
      Mode          char = 'disp' %Can be {'delete', 'return', or 'disp'}
      Monitor              % event.listener ... property listener for gcbo
      Root    (1,1) matlab.ui.Root = groot  % groot (Root graphics object)
   end
   
   % ABORTSET,DEPENDENT,SETOBSERVABLE,TRANSIENT
   properties (AbortSet,Dependent,SetObservable,Transient,Access=public)
      cbo     % Current callback object (read-only; from Root)
   end
   
   properties (AbortSet,Transient,Access=protected)
      cbo_    % Container
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % PUBLIC (constructor)
   methods (Access=public)
      % Class constructor
      function obj = ListenerMonitor(dims)
         %LISTENERMONITOR  Construct object that listens to... listeners
         %
         %  obj = nigeLab.utils.ListenerMonitor();
         
         if nargin > 0
            if numel(dims) < 2
               dims = [zeros(1,2-numel(dims)),dims];
            end
            
            obj = repmat(obj,dims);
            return;
         end
         
         obj.Monitor = addlistener(obj,'gcbo','PostSet',...
            @(~,evt)nigeLab.utils.ListenerMonitor);
      end
      
      % Change .Mode to new value
      function setMode(obj,Mode)
         %SETMODE  Change mode to 'delete', 'disp', or 'return'
         %
         %  setMode(obj,Mode);
         
         Mode = lower(Mode);
         if ismember(Mode,{'delete','disp','return'})
            obj.Mode = Mode;
            fprintf(1,...
               'ListenerMonitor mode updated: <strong>%s</strong>\n',...
               Mode);
         end
      end
   end
   
   methods (Hidden,Static,Access=public)
      function cb(evt)
         %CB  Callback for listener in obj.Monitor
         %
         %  obj.Monitor = addlistener(obj,'gcbo','PostSet',...
         %     @(~,evt)nigeLab.utils.ListenerMonitor);
         
         obj = evt.AffectedObject;
         if obj.gcbo == obj.Monitor
            % Don't care about this object's listener
            return;
         end
         switch obj.Mode
            case 'delete'
               disp('<strong>Deleted:</strong>');
               delete(obj.cbo);
            case 'disp'
               disp(obj.cbo);
            case 'return'
               lh = obj.cbo;
               nigeLab.utils.mtb(obj.RETURNED_LH_NAME,lh);
         end
      end
      
      function obj = empty()
         obj = nigeLab.utils.ListenerMonitor([0 0]);
      end
   end
   
   % NO ATTRIBUTES
   methods 
      % Overload delete to ensure .Monitor is deleted
      function delete(obj)
         if ~isempty(obj.Monitor)
            if isvalid(obj.Monitor)
               delete(obj.Monitor);
            end
         end
         
      end
      
      function value = get.cbo(obj)
         if isempty(obj.gcbo_)
            obj.cbo_ = gcbo; 
         end
         value = obj.cbo_;
      end
      function set.cbo(obj,~)
         obj.cbo_ = gcbo; 
      end
   
   end
   % % % % % % % % % % END METHODS% % %
end