classdef AcqSystem
   % ACQSYSTEM  Enumeration of properties for different acquisition systems
   
   properties (GetAccess = 'public', SetAccess = 'immutable')
      Name     % {'TDT', 'RHS' or 'RHD'}
      Fields   % Corresponds to Fields property of nigeLab.Block
      Header   % Variables to be parsed in 'ReadHeader' functions
%       Channels
%       Streams
      
      
   end
   
   methods (Access = 'public')
      function acqObj = AcqSystem(systemName)
         % ACQSYSTEM  Constructor for enumeration class for acquisition sys
         
         sys = upper(systemName);
         if ~ismember(sys,nigeLab.utils.AcqSystem.validOptions)
            error('Invalid systemName (see AcqSystem.validOptions): %s',...
               systemName);
         end
         
         acqObj.Name = sys;
         [acqObj.Fields, acqObj.Header] = nigeLab.utils.AcqSystem.(sys);
         
      end
   end
   
   methods (Static = true, Access = public)
      function sysList = validOptions()
         % VALIDOPTIONS  Return a list of valid acquisition system options
         sysList = {'TDT', 'RHS', 'RHD'};
      end      
   end
   
   methods (Static = true, Access = private)
      function [fields, header] = TDT()
         % TDT  Return fields and header enumerated for TDT system
         fields = {'Time','Raw','DigIO','AnalogIO'};
         header = nigeLab.utils.initDesiredHeaderFields('TDT');
      end  
      
      function [fields, header] = RHS()
         % RHS  Return fields and header enumerated for RHS system
         fields = {'Time','Raw','DigIO','AnalogIO','Stim','DC'};
         header = nigeLab.utils.initDesiredHeaderFields('RHS');
      end 
      
      function [fields, header] = RHD()
         % RHD  Return fields and header enumerated for RHD system
         fields = {'Time','Raw','DigIO','AnalogIO'};
         header = nigeLab.utils.initDesiredHeaderFields('RHD');
      end 
   end
   
end