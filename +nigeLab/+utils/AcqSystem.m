classdef AcqSystem
   % ACQSYSTEM  Enumeration of properties for different acquisition systems
   %
   %  Has overloaded `unique` method so that any unique acquisition objects
   %  within an array can be returned using call to `unique` (e.g. for
   %  animals with many recordings taken with some different systems)
   
   % % % PROPERTIES % % % % % % % % % %
   % PUBLIC/IMMUTABLE
   properties (GetAccess=public,SetAccess=immutable)
      Name     char  % {'TDT', 'RHS', 'RHD', or 'UNKNOWN'}
      Fields   cell  % Corresponds to Fields property of nigeLab.Block
      Header   cell  % Variables to be parsed in 'ReadHeader' functions      
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded methods)
   methods
      % Overloaded `unique` method for acqObj
      function [uObj,idx] = unique(acqObjArray)
         %UNIQUE  Overloaded `unique` method for acqObj
         %
         %  [uObj,idx] = unique(acqObjArray);
         %  uObj : Elements with unique 'Name' value
         %  idx  : Corresponding indices of those elements
         
         if isscalar(acqObjArray)
            uObj = acqObjArray;
            idx = 1;
            return;
         end
         
         name = {acqObjArray.Name};
         [~,idx,~] = unique(name);
         uObj = acqObjArray(idx);
      end
   end
   
   % PUBLIC
   methods (Access=public)
      function acqObj = AcqSystem(systemName)
         % ACQSYSTEM  Constructor for enumeration class for acquisition sys
         %
         %  acqObj = nigeLab.utils.AcqSystem('systemName');
         %
         %  'systemName'  --  valid options defined in
         %        nigeLab.utils.AcqSystem.validOptions()
         
         if nargin < 1
            systemName = 'UNKNOWN';
         end
         
         sys = upper(systemName);
         if ~ismember(sys,acqObj.validOptions)
            error('Invalid systemName : %s  (see AcqSystem.validOptions)',...
               systemName);
         end
         
         acqObj.Name = sys;
         [acqObj.Fields, acqObj.Header] = nigeLab.utils.AcqSystem.(sys);
         
      end
   end
   
   % PROTECTED
   methods (Access=protected)
      function sysList = validOptions(acqObj)
         % VALIDOPTIONS  Return a list of valid acquisition system options
         %
         %  sysList = nigeLab.utils.AcqSystem.validOptions();
         
         mc = metaclass(acqObj);
         m = mc.MethodList;
         isPrivate = ismember({m.Access},'protected');
         isStatic = [m.Static];
         methodNames = {m.Name};
         sysList = methodNames(isPrivate & isStatic);
      end      
   end
   
   % STATIC,PROTECTED (enumerations)
   methods (Static,Access=protected)
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
      
      function [fields, header] = UNKNOWN()
         % UNKNOWN  Return fields and header enumerated for UNKNOWN system
         %
         %  [fields, header] = nigeLab.utils.AcqSystem.UNKNOWN();
         %
         %  This is the default case if nigeLab.utils.AcqSystem is called
         %  with no input arguments.
         
         fields = {'Time','Raw'};
         header = nigeLab.utils.initDesiredHeaderFields(); % Same as 'All'
      end 
   end
   % % % % % % % % % % END METHODS% % %
end