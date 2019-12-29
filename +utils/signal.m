classdef signal
   % SIGNAL  Class to enumerate signal types to keep them properly grouped
   
   properties (GetAccess = 'public', SetAccess = 'immutable')
      Name      % Name of signal
      Group     % Original "signal group" given during header parsing
      SubGroup  % More granular grouping than "Group"
      Field     % Field associated with "signal group"
      FieldType % FieldType associated with that Field 
      Source    % Type of source that generated data
   end
   
   methods (Access = 'public')
      % Associate signal original with the desired "FieldType" type
      function sig = signal(group,field,fieldType,source,name,subgroup)
         % SIGNAL  Construct object to enumerate signal types for grouping
         %
         %  sig = nigeLab.utils.SIGNAL('groupname');
         %
         %  sig = nigeLab.utils.SIGNAL(group,field,fieldType);
         %  sig = nigeLab.utils.SIGNAL(___,source,name,subgroup);
         
         if nargin < 6
            subgroup = [];
         end
         
         if nargin < 5
            name = [];
         end
         
         if nargin < 4
            source = [];
         end
         
         if nargin < 3
            fieldType = [];
         end
         
         if nargin < 2
            field = [];
         end
         
         if iscell(group)
            sig = repmat(sig,numel(group),1);
            if iscell(field)
               for i = 1:numel(group)
                  sig(i) = nigeLab.utils.signal(group{i},field{i},fieldType{i},source{i},name{i},subgroup{i});
               end
            else
               for i = 1:numel(group)
                  sig(i) = nigeLab.utils.signal(group{i},field,fieldType,source,name,subgroup);
               end
            end
            return;
         end
         
         sig.Group = group;
         [sig.Field,sig.FieldType,sig.Source,sig.Name,sig.SubGroup] = sig.enum(field,fieldType,source,name,subgroup);
      end
      
      % Check if sig belongs to a group of signals or cell array or char
      % vector with for a given property, 'toMatch'
      function [idx,n] = belongsTo(varargin)
         % BELONGSTO  Checks if sig belongs to 'toCompare' using 'toMatch'
         %
         %  [idx,n] = belongsTo(sig,toCompare,toMatch);
         %
         %  toCompare  --  nigeLab.utils.signal or char array
         %  toMatch  --  Property "to match" (char array)
         %
         %  toCompare and toMatch must always be the last two inputs
         
         if numel(varargin) < 3
            error('Must provide at least 3 input arguments.');
         end
         
         toCompare = varargin{end-1};
         toMatch = varargin{end};
         varargin((end-1):end) = [];
         
         if isa(toCompare,'nigeLab.utils.signal')
            toCompare = {toCompare.(toMatch)};
         elseif ischar(toCompare)
            toCompare = {toCompare};
         end
         
         if numel(varargin) > 1
            idx = false(size(varargin));
            for i = 1:numel(varargin)
               idx(i) = belongsTo(varargin{i},toCompare,toMatch);
            end
            n = sum(idx);
            return;
         end
         
         sig = varargin{1};
         
         if any(strcmpi(sig.(toMatch),toCompare))
            idx = true;
            n = 1;
         else
            idx = false;
            n = 0;
         end
      end
   end
   
   methods (Access = 'private')
      % Define an enumeration for stream type
      function [Field,FieldType,Source,Name,SubGroup] = enum(sig,Field,FieldType,Source,Name,SubGroup)
         % ENUM  Define the enumeration using switch case statement
         
         % Handle different amounts of inputs. If an input field is empty,
         % the part at the end will allow the switch ... case statement to
         % assign the enumeration. Otherwise, the input value is used.
         if nargin < 6
            SubGroup = [];
         end
         
         if nargin < 5
            Name = [];
         end
         
         if nargin < 4
            Source = [];
         end
         
         if nargin < 3
            FieldType = [];
         end
         
         if nargin < 2
            Field = [];
         end
         
         str = nigeLab.utils.signal.cleanString(sig.Group);
         switch str
            case {'DIGIN','DIGITALIN','DIGOUT','DIGITALOUT'}
               field = 'DigitalIO';
               fieldType = 'Streams';
               source = 'ephys';
               name = str;
               subgroup = [];
               
            case {'ANAIN','ANAOUT','ANALOGIN','ANALOGOUT','ADC','DAC','SUPPLY','AUX'}
               field = 'AnalogIO';
               fieldType = 'Streams';
               source = 'ephys';
               name = str;
               subgroup = [];
               
            case {'RAW','FILT','SPIKES','SORT','CLUSTERS','LFP','ARTIFACT','SPIKEFEATURES'}
               field = [];
               fieldType = 'Channels';
               source = 'ephys';
               name = [];
               subgroup = [];
               
            case {'SYNC','KINEMATICS','MARKERS','MARKER'}
               field = 'VidStreams';
               fieldType = 'Videos';
               source = 'video';
               name = sig.Group;
               subgroup = [];
               
            case {'PAW','BTN','BUTTON','BEAM','TRIALRUNNING'}
               field = 'VidStreams';
               fieldType = 'Videos'; % Maybe Streams, need to figure out parsing
               source = 'video';
               name = sig.Group;
               subgroup = [];
               
            case {'MP4','AVI','MOV'}
               field = 'Video';
               fieldType = 'Videos';
               source = 'video';
               name = sig.Group;
               subgroup = [];
               
            otherwise
               field = [];
               fieldType = [];
               source = [];
               name = [];
               subgroup = [];
               warning('Mismatch for original signal-type: %s',str);
         end
         
         % Assign outputs
         if isempty(Field)
            Field = field;
         end
         
         if isempty(FieldType)
            FieldType = fieldType;
         end
         
         if isempty(Source)
            Source = source;
         end
         
         if isempty(Name)
            Name = name;
         end
         
         if isempty(SubGroup)
            SubGroup = subgroup;
         end
         
      end
   end
   
   methods (Static = true)
      % Clean up unwanted parts of an input string
      function str = cleanString(signal_group)
         str = strrep(signal_group,'.','');
         str = strrep(str,'*','');
         str = upper(str);
      end
   end
   
   
end

