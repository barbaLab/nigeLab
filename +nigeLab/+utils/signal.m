classdef signal
   % SIGNAL  Class to enumerate signal types to keep them properly grouped
   
   % % % PROPERTIES % % % % % % % % % %
   % PUBLIC
   properties (GetAccess=public,SetAccess=public)
      Samples     double   % Number of samples for this signal
   end
   
   % PUBLIC/IMMUTABLE
   properties (GetAccess=public,SetAccess=immutable)
      Name        char     % Name of signal
      Group       char     % Original "signal group" given during header parsing
      SubGroup    char     % More granular grouping than "Group"
      Field       char     % Field associated with "signal group"
      FieldType   char     % FieldType associated with that Field 
      Source      char     % Type of source that generated data
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % PUBLIC
   methods (Access=public)
      % Associate signal original with the desired "FieldType" type
      function sig = signal(group,samples,field,fieldType,source,name,subgroup)
         % SIGNAL  Construct object to enumerate signal types for grouping
         %
         %  sig = nigeLab.utils.SIGNAL('groupname');
         %
         %  sig = nigeLab.utils.SIGNAL(group,samples,field,fieldType,...
         %                                source,name,subgroup);
         %
         %  INPUTS
         %  ------
         %  group : Signal grouping. Can be
         %           * 'DigIO' or 'AnalogIO' (for streams)
         %           * 'Raw' or 'Filt' or 'Spikes' etc (for channels)
         %           * 'Sync' or 'Kinematics' or 'Marker' (for VidStreams)
         %           * 'Paw' or 'Btn' or 'Beam' (also VidStreams)
         %           * 'MP4' or 'AVI' or 'MOV' (Videos)
         %  
         %  samples : Number of samples 
         %            --> This is the only property that can be modified
         %                AFTER the constructor
         %
         %  field : Field associated with signal group
         %           * Corresponds to `Fields` property
         %
         %  fieldType : Corresponds to `FieldType` property
         %
         %  source : Where did the signal come from
         %           * Either 'AcqSystem' or 'Video'
         %
         %  name : Typically the same as .Group
         %
         %  subgroup : For VidStreams; see ~/+nigeLab/+defaults/Video.m
         %              --> pars.VidStreamSubGroup
         %              ('p','x','y','z', or 'discrete' currently)
         
         if nargin < 7
            subgroup = '';
         end
         
         if nargin < 6
            name = '';
         end
         
         if nargin < 5
            source = '';
         end
         
         if nargin < 4
            fieldType = '';
         end
         
         if nargin < 3
            field = '';
         end
         
         if nargin < 2
            samples = [];
         end
         
         if nargin < 1
            group = '';
         end
         
         if iscell(group)
            sig = repmat(sig,numel(group),1);
            if iscell(field)
               if numel(samples) == 1
                  samples = repmat(samples,numel(field),1);
               end
               for i = 1:numel(group)
                  sig(i) = nigeLab.utils.signal(...
                     group{i},...
                     samples(i),...
                     field{i},...
                     fieldType{i},...
                     source{i},...
                     name{i},...
                     subgroup{i});
               end
            else
               for i = 1:numel(group)
                  sig(i) = nigeLab.utils.signal(...
                     group{i},...
                     samples,...
                     field,...
                     fieldType,...
                     source,...
                     name,...
                     subgroup);
               end
            end
            return;
         end
         
         sig.Group = group;
         [sig.Samples,sig.Field,sig.FieldType,sig.Source,sig.Name,sig.SubGroup] = sig.enum(field,fieldType,source,name,subgroup,samples);
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
   
   % PROTECTED
   methods (Access=protected)
      % Define an enumeration for stream type
      function [Samples,Field,FieldType,Source,Name,SubGroup] = enum(sig,Field,FieldType,Source,Name,SubGroup,Samples)
         % ENUM  Define the enumeration using switch case statement
         
         % Handle different amounts of inputs. If an input field is empty,
         % the part at the end will allow the switch ... case statement to
         % assign the enumeration. Otherwise, the input value is used.         
         if nargin < 7
            SubGroup = '';
         end
         
         if nargin < 6
            Name = '';
         end
         
         if nargin < 5
            Source = '';
         end
         
         if nargin < 4
            FieldType = '';
         end
         
         if nargin < 3
            Field = '';
         end
         
         if nargin < 2
            Samples = [];
         end
         
         str = nigeLab.utils.signal.cleanString(sig.Group);
         switch str
            case {'DIGIN','DIGITALIN','DIGOUT','DIGITALOUT'}
               field = 'DigIO';
               fieldType = 'Streams';
               source = 'AcqSystem';
               name = str;
               subgroup = 'dig';
               samples = [];
               
            case {'ANAIN','ANAOUT','ANALOGIN','ANALOGOUT','ADC','DAC','SUPPLY','AUX'}
               field = 'AnalogIO';
               fieldType = 'Streams';
               source = 'AcqSystem';
               name = str;
               subgroup = 'analog';
               samples = [];
               
            case {'RAW','FILT','SPIKES','SORT','CLUSTERS','LFP','ARTIFACT','SPIKEFEATURES'}
               field = sig.Group;
               fieldType = 'Channels';
               source = 'AcqSystem';
               name = str;
               subgroup = 'data';
               samples = [];
               
            case {'SYNC','KINEMATICS','MARKERS','MARKER'}
               field = 'VidStreams';
               fieldType = 'Videos';
               source = 'Video';
               name = sig.Group;
               subgroup = '';
               samples = [];
               
            case {'PAW','BTN','BUTTON','BEAM','TRIALRUNNING'}
               field = 'VidStreams';
               fieldType = 'Videos'; % Maybe Streams, need to figure out parsing
               source = 'Video';
               name = sig.Group;
               subgroup = '';
               samples = [];
               
            case {'MP4','AVI','MOV'}
               field = 'Video';
               fieldType = 'Videos';
               source = 'Video';
               name = sig.Group;
               subgroup = '';
               samples = [];
               
            otherwise
               field = '';
               fieldType = '';
               source = '';
               name = '';
               subgroup = '';
               samples = [];
               if ~ismember(str,{'EMPTY',''})
                  warning('Mismatch for original signal-type: %s',str);
               end
         end
         
         % Assign outputs
         if isempty(Samples)
            Samples = samples;
         end
         
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
   
   % STATIC,PUBLIC
   methods (Static,Access=public)
      % Clean up unwanted parts of an input string
      function str = cleanString(signal_group)
         str = strrep(signal_group,'.','');
         str = strrep(str,'*','');
         str = upper(str);
      end
   end
   % % % % % % % % % % END METHODS% % %
   
end

