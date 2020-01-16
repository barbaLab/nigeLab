classdef SortUI < handle & matlab.mixin.SetGet
   %SORTUI  Handle class to graphics handles for Spike Sorting Interface
   %
   %  Small "helper" class with property handles that integrate the
   %  nigeLab.libs.ChannelUI, nigeLab.libs.SpikeImage, and
   %  nigeLab.libs.FeaturesUI classes.
   %
   %  SORTUI Properties
   %     ch : Current channel
   %
   %     cl : Current cluster
   %
   %     plot : Parameters associated with "plots"
   %
   %     feat : Parameters associated with "features" axes
   %
   %     ChannelSelector : Modular "channel selection" popupbox figure
   %     --> Class: nigeLab.libs.ChannelUI
   %
   %     FeaturesUI : Modular "features" 2D and 3D plot figure
   %     --> Class: nigeLab.libs.FeaturesUI
   %
   %     Listeners : Event listeners that unify "sub" interfaces
   %
   %     SpikeImage : Modular "spike clusters" cluster assignment interface
   %     --> Class: nigeLab.libs.SpikeImage
   %
   %  SORTUI Methods
   %     SortUI : Class constructor. Can only be called from nigeLab.Sort.
   %
   %     delete : Overloaded delete method to handle destruction of UIs
   
   % % % PROPERTIES % % % % % % % % % %
   % DEPENDENT,PUBLIC
   properties (Dependent,Access=public)
      channel   (1,1) double % Depends on SortUI.ch
      cluster   (1,1) double % Depends on SortUI.cl
      value     (1,1) double % Depends on SortUI.cl
   end
   
   % HIDDEN,PUBLIC
   properties (Hidden,Access=public)
      ch    (1,1)    double = 1  % Current channel
      cl    (1,1)    double = 1  % Current cluster
      plot  (1,1)    struct      % "plot" parameters
      feat  (1,1)    struct      % "features" parameters
   end
   
   % TRANSIENT,PUBLIC
   properties (Transient,Access=public)
      ChannelSelector                  % Modular "channel selector" popupbox figure
      FeaturesUI                       % Modular "features" 2D and 3D plot figure
      Listeners         event.listener % Listeners for ChannelSelector, FeaturesUI, and SpikeImage
      Parent                           % nigeLab.Sort parent
      SpikeImage                       % Modular "spike clusters" snippet display figure
   end   
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded methods)
   methods
      % Overload of delete method
      function delete(obj)
         %DELETE Handles destructor of SortUI
         %
         %  delete(obj);
         
         % Remove any listener objects
         if ~isempty(obj.Listeners)
            for lh = obj.Listeners
               if isvalid(lh)
                  delete(lh);
               end
            end
         end
         
         % Remove the channel selector UI, if it exists
         if ~isempty(obj.ChannelSelector)
            if isvalid(obj.ChannelSelector)
               delete(obj.ChannelSelector);
            end
         end
         
         % Remove "FeaturesUI", if it exists
         if ~isempty(obj.FeaturesUI)
            if isvalid(obj.FeaturesUI)
               delete(obj.FeaturesUI);
            end
         end
         
         % Remove the spike interface, if it exists
         if ~isempty(obj.SpikeImage)
            if isvalid(obj.SpikeImage)
               delete(obj.SpikeImage);
            end
         end
         
      end
      
      % % % GET.PROPERTY METHODS % % % % % % % % % % % %
      % [DEPENDENT] Return .channel property
      function value = get.channel(obj)
         value = obj.ch;
      end
      
      % [DEPENDENT] Return .cluster property
      function value = get.cluster(obj)
         value = obj.cl;
      end
      
      % [DEPENDENT] Return .value property
      function value = get.value(obj)
         value = obj.cl;
      end
      % % % % % % % % % % END GET.PROPERTY METHODS % % %
      
      % % % SET.PROPERTY METHODS % % % % % % % % % % % %
      % [DEPENDENT] Set .channel property
      function set.channel(obj,value)
         if ~isnumeric(value) || (value < 1)
            warning('Channel value must be a positive integer.');
            return;
         end

         if (value > obj.Parent.Channels.N)
            warning('Only %d channels detected. %d is too large.',...
               obj.Parent.Channels.N,value);
            return;
         end

         obj.ch = value;
      end
      
      % [DEPENDENT] Set .cluster property
      function set.cluster(obj,value)
         if ~isnumeric(value) || (value < 1)
            warning('Channel value must be a positive integer.');
            return;
         end

         if (value > obj.Parent.pars.NCLUS_MAX)
            warning('Only %d clusters allowed. %d is too large.',...
               obj.Parent.pars.NCLUS_MAX,value);
            return;
         end

         obj.cl = value;
      end
      
      % [DEPENDENT] Set .value property
      function set.value(obj,value)
         if ~isnumeric(value) || (value < 1)
            warning('Channel value must be a positive integer.');
            return;
         end

         if (value > obj.Parent.pars.NCLUS_MAX)
            warning('Only %d clusters allowed. %d is too large.',...
               obj.Parent.pars.NCLUS_MAX,value);
            return;
         end

         obj.cl = value;
      end
      % % % % % % % % % % END SET.PROPERTY METHODS % % %
   end
   
   % RESTRICTED:nigeLab.Sort (Constructor)
   methods (Access={?nigeLab.Sort,?nigeLab.SortUI})
      % Sort UI constructor
      function obj = SortUI(sortObj)
         %SORTUI  Construct graphics handles for Spike Sorting UI
         
         if nargin == 0
            % Return empty object
            return;
         end
         
         if ~isfield(sortObj.pars,'SpikePlotXYExtent')
            if ~sortObj.setAxesPositions
               error(['nigeLab:' mfilename ':BadInputParams'],...
                  ['Could not set axes positions correctly.\n' ...
                   '-->\tCheck nigeLab.Sort.pars\n']);
            end
         end
         
         % Set Parent object
         obj.Parent = sortObj;
         
         % Initialize parameters for spike plots
         obj.plot.zoom = ones(sortObj.pars.SpikePlotN,1) * 100;
         obj.plot.ylim = repmat(sortObj.pars.SpikePlotYLim,...
            sortObj.pars.SpikePlotN,1);

         % Initialize "features" info
         obj.feat.cur = 1;
         obj.feat.combo = nchoosek(1:size(sortObj.spk.feat{1},2),2);
         obj.feat.n = size(obj.feat.combo,1);
         obj.feat.name = obj.parseFeatNames();
         obj.feat.label = obj.parseFeatLabels();
      end
      
      % Add ChannelSelector to UI
      function addChannelSelector(obj)
         %ADDCHANNELSELECTOR  Method to add ChannelSelector to UI
         
         sortObj = obj.Parent;
         obj.ChannelSelector(:) = [];
         obj.ChannelSelector = nigeLab.libs.ChannelUI(obj);
         obj.Listeners = [obj.Listeners, ...
            addlistener(obj.ChannelSelector,'NewChannel',...
            @sortObj.setChannel)];
      end
      
      % Add FeaturesUI to UI
      function addFeaturesUI(obj)
         %ADDSPIKEIMAGE  Method to add SpikeImage to UI

         obj.FeaturesUI = nigeLab.libs.FeaturesUI(obj);
      end
      
      % Add SpikeImage to UI
      function addSpikeImage(obj)
         %ADDSPIKEIMAGE  Method to add SpikeImage to UI
         
         sortObj = obj.Parent;
         obj.SpikeImage(:) = [];
         obj.SpikeImage = nigeLab.libs.SpikeImage(obj,...
            [],[],'ProgCatPars',sortObj.progCatPars);

         obj.Listeners = [obj.Listeners, ...
            addlistener(obj.SpikeImage,'MainWindowClosed',...
               @(~,~)sortObj.delete), ...
            addlistener(obj.SpikeImage,'SaveData',...
               @(~,~)sortObj.saveData)];
      end

      featLabel = parseFeatLabels(obj)   % Parse pairs of feature names for dropdown labels list
      featName = parseFeatNames(obj)     % Parse feature names
   end
   % % % % % % % % % % END METHODS% % %
end