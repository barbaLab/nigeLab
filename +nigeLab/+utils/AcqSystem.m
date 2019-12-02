classdef AcqSystem
   % ACQSYSTEM  Enumeration of properties for different acquisition systems
   
   properties (GetAccess = 'public', SetAccess = 'immutable')
      Name     % {'TDT', 'RHS' or 'RHD'}
      Fields   % Corresponds to Fields property of nigeLab.Block
      Header   % Variables to be parsed in 'ReadHeader' functions      
   end
   
   methods (Access = 'public')
      function acqObj = AcqSystem(systemName)
         % ACQSYSTEM  Constructor for enumeration class for acquisition sys
         %
         %  acqObj = nigeLab.utils.AcqSystem('systemName');
         %
         %  'systemName'  --  valid options defined in
         %        nigeLab.utils.AcqSystem.validOptions()
         
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
         %
         %  sysList = nigeLab.utils.AcqSystem.validOptions();
         
         sysList = {'TDT', 'RHS', 'RHD'};
      end      
   end
   
   % Matlab Enumeration is buggy so do it this way
   methods (Static = true, Access = private)
      function [fields, header] = TDT()
         % TDT  Return fields and header enumerated for TDT system
         %
         %  [fields, header] = nigeLab.utils.AcqSystem.TDT();
         %
         %  example usage:
         %  acqsys = 'TDT';  % Parsed from elsewhere
         %  [fields, header] = nigeLab.utils.AcqSystem.(acqsys);
         
         fields = {'Time','Raw','DigIO','AnalogIO'};
         header = nigeLab.utils.initDesiredHeaderFields('TDT');
      end  
      
      function [fields, header] = RHS()
         % RHS  Return fields and header enumerated for RHS system
         %
         %  [fields, header] = nigeLab.utils.AcqSystem.RHS();
         %
         %  example usage:
         %  acqsys = 'RHS';  % Parsed from elsewhere
         %  [fields, header] = nigeLab.utils.AcqSystem.(acqsys);
         
         fields = {'Time','Raw','DigIO','AnalogIO','Stim','DC'};
         header = nigeLab.utils.initDesiredHeaderFields('RHS');
      end 
      
      function [fields, header] = RHD()
         % RHD  Return fields and header enumerated for RHD system
         %
         %  [fields, header] = nigeLab.utils.AcqSystem.RHD();
         %
         %  example usage:
         %  acqsys = 'RHD';  % Parsed from elsewhere
         %  [fields, header] = nigeLab.utils.AcqSystem.(acqsys);
         
         fields = {'Time','Raw','DigIO','AnalogIO'};
         header = nigeLab.utils.initDesiredHeaderFields('RHD');
      end 
   end
   
end