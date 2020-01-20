classdef Sort < handle
%SORT  User interface for "cluster-cutting" to manually classify spikes
%
%  nigeLab.Sort;
%  sortObj = nigeLab.Sort;
%  sortObj = nigeLab.Sort(nigelObj);
%
%   --------
%    INPUTS
%   --------
%   nigelObj  :     (Optional) If not provided, a UI for generation or
%                       loading of the correct orgExpObj pops up.
%                       Otherwise, the Sort class object parses which
%                       orgExpObj is given (based on object class), and
%                       presents the Sort interface based on that.
%
%   --------
%    OUTPUT
%   --------
%   Provides a graphical interface to combine and/or restrict spikes
%   included in each cluster. Works with spikes that have been extracted
%   using the NIGELAB workflow.
   
   % % % PROPERTIES % % % % % % % % % %   
   % PUBLIC/PROTECTED
   properties (GetAccess=public,SetAccess=protected)
      nigelDash                           % Handle to DashBoard (if exists)
      pars                                % Parameters
      progCatPars = struct(...            % Parameters for "progressCat"
                           'imgStrDef','Nigel_%03g.jpg',...
                           'nImg',11,...
                           'pawsInterval',0.05,...
                           'progPctThresh',4);
      spk                                 % Contains spike snippets
      UI                                  % UI controller class
   end
   
   % PROTECTED
   properties (Access=protected)
      Input    % Original nigelObj array
      orig     % Original assignments
      prev     % Previous assignments
   end
   
   % PUBLIC
   properties (Access=public)
      Blocks                     % Array of nigeLab.Block objects
      Channels                   % Struct containing channels info
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % EVENTS % % % % % % % % % % % %
   % PUBLIC
   events (ListenAccess=public,NotifyAccess=public)
      ChannelUpdated
   end
   % % % % % % % % % % END EVENTS % % %
   
   % % % METHODS% % % % % % % % % % % %
   % RESTRICTED:nigeLab.nigelObj (method: .Sort)
   methods (Access={?nigeLab.nigelObj,?nigeLab.Sort,...
                    ?nigelab.Block,?nigeLab.Animal,?nigeLab.Tank})
   % Class constructor
      function sortObj = Sort(nigelObj)
         %SORT  Sort class object constructor
         %
         %  nigeLab.Sort;
         %  sortObj = nigeLab.Sort;
         %  sortObj = nigeLab.Sort(nigelObj);                       
         
         % Initialize input data
         if nargin > 0
            if isnumeric(nigelObj) % Initialize
               dims = nigelObj;
               sortObj = repmat(sortObj,dims);
               return;
            end
            
            % Initialize parameters
            if ~initParams(sortObj,nigelObj)
               error(['nigeLab:' mfilename ':BadInit'],...
                     'Could not set parameters for sortObj.');
            end
            
            if ~initData(sortObj,nigelObj)
               error(['nigeLab:' mfilename ':BadInit'],...
                  'sortObj array not created successfully.');
            end
%          else       % Note: it is no longer possible to call `Sort`
%                     %       constructor from Command Window directly; has
%                     %       to be called via a `nigelObj` method
%                     %       2020-01-20 -MM
%
%             % Initialize parameters
%             if ~initParams(sortObj)
%                error(['nigeLab:' mfilename ':BadInit'],...
%                      'Could not set parameters for sortObj.');
%             end
%             % And then initialize data
%             if ~initData(sortObj)
%                error(['nigeLab:' mfilename ':BadInit'],...
%                   'sortObj array not created successfully.');
%             end
         else % Therefore, if it is given without inputs, it is for init
            sortObj = nigeLab.Sort([0,0]); % Empty
            close(gcf);
            return;
         end
         
         % Initialize graphical interface
         if ~initUI(sortObj)
            error('Error constructing graphical interface for sorting.');
         end
         
         if nargout == 0
            clear sortObj
         end
      end
   end
      
   % NO ATTRIBUTES (overloaded methods)
   methods      
      % Overloaded `delete` method
      function delete(sortObj)
         %DELETE  Ensure that objects are destroyed on sortObj destructor
         %
         %  delete(sortObj);

         % Remove the channel selector UI, if it exists
         if ~isempty(sortObj.UI)
            if isvalid(sortObj.UI)
               delete(sortObj.UI);
            end 
         end
         
         % Remove association from input
         if ~isempty(sortObj.Input)
            set(sortObj.Input,'SortGUI',[]);
         end
      end
      
      % Overloaded `set` method
      function flag = set(sortObj,name,value)
         %SET   Overloaded set method for the nigeLab.Sort class object
         %
         %  flag = set(sortObj,'Name',value);
         
         flag = false;
         switch lower(name)
            case 'channel'
               if ~isnumeric(value) || (value < 1)
                  warning('Channel value must be a positive integer.');
                  return;
               end
               
               if (value > sortObj.Channels.N)
                  warning('Only %d channels detected. %d is too large.',...
                     sortObj.Channels.N,value);
                  return;
               end
               
               sortObj.UI.ch = value;
               
            case 'cluster'
               if ~isnumeric(value) || (value < 1)
                  warning('Channel value must be a positive integer.');
                  return;
               end
               
               if (value > sortObj.pars.NCLUS_MAX)
                  warning('Only %d clusters allowed. %d is too large.',...
                     sortObj.pars.NCLUS_MAX,value);
                  return;
               end
               
               sortObj.UI.cl = value;
            
            otherwise
               builtin('set',sortObj,name,value);
         end
         flag = true;
               
         
      end
      
      % Overloaded `get` method
      function value = get(sortObj,name)
         %GET   Overloaded get method for the nigeLab.Sort class object
         switch lower(name)
            case 'channel'
               value = sortObj.UI.ch;
               
            case 'cluster'              
               value = sortObj.UI.cl;
            
            otherwise
               builtin('get',sortObj,name);
         end
      end
   end
   
   % PUBLIC
   methods (Access=public)
      setChannel(sortObj,~,~) % Set the current channel in the UI
      setClass(sortObj,class) % Set the current sort class
      saveData(sortObj)       % Save the sorting
   end
   
   % PROTECTED
   methods (Access=protected)      
      flag = initParams(sortObj,nigelObj); % Initialize general parameters
      flag = initData(sortObj,nigelObj); % Initialize data structures
      flag = initUI(sortObj); % Initializes spike scoring UI parameters
      
      [spikes,feat,class,tag,ts,blockIdx] = getAllSpikeData(sortObj,ch); % Get spike info from all channels
      
      flag = parseBlocks(sortObj,nigelObj);  % Assigns Blocks property
      flag = parseAnimals(sortObj,nigelObj); % Assigns Blocks from Animals
      
      flag = setAxesPositions(sortObj); % Draw axes positions
      
      channelName = parseChannelName(sortObj); % Get all channel names
   end
   % % % % % % % % % % END METHODS% % %
end