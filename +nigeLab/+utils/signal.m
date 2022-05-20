classdef signal < matlab.mixin.SetGet
   % SIGNAL  Handle class that enumerates signal properties for grouping
   %
   %  sig = nigeLab.utils.signal(group,samples,field,fieldType);
   %  sig = nigeLab.utils.signal(___,source,name,subgroup);
   %
   %  SIGNAL Properties:
   %  Samples  --  (double) Number of samples in this signal
   %
   %  Name  --  (char)  Name of signal
   %
   %  Group  --  (char)  Original "signal group" given during header parse
   %     NOTE: VERY IMPORTANT IN DORAWEXTRACTION
   %
   %  SubGroup  --  (char)  More granular grouping than "Group" property
   %     NOTE: USED IN VIDEOSFIELDTYPE/VIDSTREAMS STUFF
   %     Example: splits .Group (which would be 'Marker' or 'Sync' for
   %               VidStreams-related signal) into {'p','x','y','z'} for
   %               Marker or {'stream' / 'discrete'} for Sync etc.
   %
   %  Field   --  (char)  Field associated with signal group
   %     NOTE: VERY IMPORTANT IN DORAWEXTRACTION
   %
   %  FieldType  -- (char)  FieldType associated with .Field property
   %
   %  Source  -- (char)  Type of source that generated data
   %     NOTE: This can sometimes be nigeLab.utils.AcqSys class object that
   %           gives enumerated info about specific kinds of acquisition
   %           systems (such as Intan RHS or RHD headstages, or
   %           Tucker-Davis Technologies [TDT] acquisition system)
   
   % % % PROPERTIES % % % % % % % % % %
   % PUBLIC
   properties (GetAccess=public,SetAccess=public)
      Samples     double   % Number of samples for this signal
   end
   
   % DEPENDENT,TRANSIENT,PUBLIC
   properties (Dependent,Transient,Access=public)
      FileType    char     % {'MatFile', or 'Hybrid', or 'Event'}
   end
   
   % PUBLIC/IMMUTABLE
   properties (GetAccess=public,SetAccess=immutable)
      Name        char     % Name of signal
      Group       char     % Original "signal group" given during header parsing NOTE: VERY IMPORTANT IN DORAWEXTRACTION
      SubGroup    char     % More granular grouping than "Group" NOTE: USED IN VIDEOSFIELDTYPE/VIDSTREAMS STUFF
      Field       char     % Field associated with "signal group" NOTE: VERY IMPORTANT IN DORAWEXTRACTION
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
   end
   
   % NO ATTRIBUTE (overloaded)
   methods
      % [DEPENDENT]  Property GET method for .FileType (depends .Field)
      function value = get.FileType(obj)
         %GET.FILETYPE  Returns .FileType (depends on .Field)
         %
         %  value = get(obj,'FileType');
         
         switch lower(obj.Field)
            case {'raw','filt','lfp','car',...
                  'digio','analogio',...
                  'time','vidstreams'}
               value = 'MatFile';
            case {'artifact','spikes','spikefeatures',...
                  'clusters','sorted','sort',...
                  'digevents','stim','scoredevents'}
               value = 'Event';
            case {'probes'}
               value = 'Other';
         end
      end
      
      % [DEPENDENT]  Property SET method for .FileType (cannot set)
      function set.FileType(~,~)
         %SET.FILETYPE  Does nothing
         nigeLab.sounds.play('pop',2.7);
         dbstack();
         nigeLab.utils.cprintf('Errors*','[UTILS.SIGNAL]: ');
         nigeLab.utils.cprintf('Errors',...
            'Failed attempt to set DEPENDENT property: FileType\n');
         fprintf(1,'\n');
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
               
            case {'DATA','RAW','FILT','LFP','SPIKES','SPIKE','SORTED','SORT','CLUSTERS','ARTIFACT','SPIKEFEATURES'}
               field = sig.Group;
               fieldType = 'Channels';
               source = 'AcqSystem';
               name = str;
               subgroup = '';
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
               
            case {'MP4','AVI','MOV','VID'}
               field = 'Video';
               fieldType = 'Videos';
               source = 'Video';
               name = sig.Group;
               subgroup = '';
               samples = [];
            
            case {'STANDARD','HEADER','TRIAL','FSM'}
               field = '';
               fieldType = 'Events';
               source = '';
               name = '';
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

