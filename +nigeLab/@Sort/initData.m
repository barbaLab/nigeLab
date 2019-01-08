function flag = initData(sortObj,nigelObj)
%% INIT Initialize handles structure for Combine/Restrict Cluster UI.
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
         parseBlocks(nigelObj);
      case 'nigeLab.Animal'
         parseAnimals(nigelObj);
      case 'nigeLab.Tank'
         if numel(nigelObj) > 1
            warning('Only 1 nigeLab.Tank object can be scored at a time.');
            return;            
         else
            sortObj.data = parseAnimals(nigelObj.Animals);
         end         
      otherwise
         warning(['%s is an invalid input type.\n' ...
                  'Must be a Block, Animal, or Tank object array.'],...
                  class(nigelObj(1)));
         return;
   end
   
else   
   
end

end