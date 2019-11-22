classdef signal
   % SIGNAL  Class to enumerate signal types to keep them properly grouped
   
   properties (GetAccess = 'public', SetAccess = 'immutable')
      orig % Original value given during header parsing
      type % FieldType associated with that signal_type value
   end
   
   methods (Access = 'public')
      % Associate signal original with the desired "FieldType" type
      function sig = signal(original_type)
         % SIGNAL  Construct object to enumerate signal types for grouping
         
         sig.orig = original_type;
         sig.type = sig.enum;
      end
      
      % OVERLOADED ismember method returns index when .orig matches 'type'
      function [idx,n] = ismember(sig,type)
         % ISMEMBER  Checks if signal matches an input signal/signal.orig
         
         if isa(type,'nigeLab.utils.signal')
            type = {type.orig};
         elseif ischar(type)
            type = {type};
         end
         
         if numel(sig) > 1
            idx = false(size(sig));
            for i = 1:numel(sig)
               idx(i) = ismember(sig(i),type);
            end
            n = sum(idx);
            return;
         end
         
         if any(strcmpi(sig.orig,type))
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
      function type = enum(sig)
         % ENUM  Define the enumeration using switch case statement
         
         str = nigeLab.utils.signal.cleanString(sig.orig);
         switch str
            case {'DIGIN','DIGITALIN','DIGOUT','DIGITALOUT'}
               type = 'DigitalIO';
            case {'ANAIN','ANAOUT','ANALOGIN','ANALOGOUT','ADC','DAC','SUPPLY','AUX'}
               type = 'AnalogIO';
            case {'RAW','FILT','SPIKES','SORT','CLUSTERS','LFP','LFPDATA','RAWDATA'}
               type = 'Channels';
            case {'MP4','AVI','MOV'}
               type = 'VidStreams';
            otherwise
         end
      end
   end
   
   methods (Static = true)
      % Clean up unwanted parts of an input string
      function str = cleanString(orig)
         str = strrep(orig,'.','');
         str = strrep(str,'*','');
         str = upper(str);
      end
   end
   
   
end

