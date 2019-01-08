function flag = initData(sortObj,nigelObj)
%% INITDATA  Initialize data structure for Spike Sorting UI
%
%  flag = INITDATA(sortObj);
%  flag = INITDATA(sortObj,nigelObj);
%
%  --------
%   INPUTS
%  --------
%   sortObj    :     nigeLab.Sort class object that is under construction.
%
%  nigelObj    :     (Optional) Can be either:
%                       -> 1 or more nigeLab.Block objects
%                       -> 1 or more nigeLab.Animal objects
%                       -> 1 nigeLab.Tank object
%
% By: Max Murphy  v3.0    01/07/2019 Port to object-oriented architecture.
%                 v2.0    10/03/2017 Added ability to handle multiple input
%                                    probes with redundant channel labels.
%                 v1.0    08/18/2017 Original version (R2017a)

%% PARSE INPUT
flag = false;
if nargin > 1
   % Parse input argument type
   switch class(nigelObj(1))
      case 'nigeLab.Block'
         if ~parseBlocks(sortObj,nigelObj)
            warning('Could not parse nigeLab.Block objects.');
            return;
         end
      case 'nigeLab.Animal'
         if ~parseAnimals(sortObj,nigelObj)
            warning('Could not parse nigeLab.Animal objects.');
            return;
         end
      case 'nigeLab.Tank'
         if numel(nigelObj) > 1
            warning('Only 1 nigeLab.Tank object can be scored at a time.');
            return;            
         else
            if ~parseAnimals(sortObj,nigelObj.Animals)
               warning('Could not parse nigeLab.Animal objects.');
               return;
            end
         end         
      otherwise
         warning(['%s is an invalid input type.\n' ...
                  'Must be a Block, Animal, or Tank object array.'],...
                  class(nigelObj(1)));
         return;
   end
   
else   
   [fName,pName,~] = uigetfile(sortObj.pars.INFILE_FILT,...
                               sortObj.pars.INFILE_PROMPT,...
                               sortObj.pars.INFILE_DEF_DIR,...
                               'MultiSelect','on');
                               
   if iscell(fName) % Load array and run using recursion
      nigelObjArray = [];
      for ii = 1:numel(fName)
         in = load(fullfile(pName,fName{ii}));
         f = fieldnames(in);
         nigelObjArray = [nigelObjArray; in.(f{1})]; %#ok<AGROW>
      end
      flag = initData(sortObj,nigelObjArray);
      return;
      
   else % Otherwise, just load it and run init using recursion
      in = load(fullfile(pName,fName));
      f = fieldnames(in);
      flag = initData(sortObj,in.(f{1}));
      return;
   end
   
end
flag = true;
end