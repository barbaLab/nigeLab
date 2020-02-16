function properties = getopt(properties,varargin)
%GETOPT - Process paired optional arguments as 'prop1',val1,'prop2',val2,...
%
%  getopt(properties,varargin) 
%  >> properties = getopt(properties,'name1',val1,'name2',val2,...);
%
%  --> returns a modified properties structure, given an initial properties 
%      structure, and a list of paired arguments.
%      * Each argument pair should be of the form property_name,val where
%        property_name is the name of one of the field in properties, 
%        and val is the value to be assigned to that structure field.
%
%  getopt(properties,{'name1',val1,'name2',val2})
%
%  --> effectively the same as previous syntax
%
%  getopt(properties,matchtype,varargin);
%  >> properties = getopt(properties,0,'name1',val1,...);
%  >> properties = getopt(properties,1,'name1',val1,...);
%  >> properties = getopt(properties,2,'name1',val1,...);
%  >> properties = getopt(properties,3,'name1',val1,...);
%  >> properties = getopt(properties,4,'name1',val1,...);
%  >> properties = getopt(properties,5,'name1',val1,...);
%
%  --> Same as previous two cases, except slight change in property
%        "matching" behavior:
%  Case 0 (default): Each property name must match (case-sensitive); throws
%                    an error if there is a mismatched name.
%  Case 1: Each property name must match (case-insensitive); throws
%                    an error if there is a mismatched name.
%  Case 2: Property must match (case-sensitive) for assignment; does not
%           throw an error on mismatch and instead just skips assignment.
%  Case 3: Property must match (case-insensitive) for assignment; does not
%           throw an error on mismatch and instead just skips assignment.
%  Case 4: Property does not need to match (case-sensitive) for assignment.
%           Creates a new field if that field did not exist in `properties`
%  Case 5: Property does not need to match (case-insensitive) for
%           assignment. Create new field in `properties` if not existant.
%
%     EXAMPLE:
%   properties = struct('zoom',1.0,'aspect',1.0,'gamma',1.0,'file',[],'bg',[]);
%   properties = getopt(properties,'aspect',0.76,'file','mydata.dat')
% would return:
%   properties =
%         zoom: 1
%       aspect: 0.7600
%        gamma: 1
%         file: 'mydata.dat'
%           bg: []
%
% Typical usage in a function:
%   properties = getopt(properties,varargin{:})
%
% Function from
% http://mathforum.org/epigone/comp.soft-sys.matlab/sloasmirsmon/bp0ndp$crq5@cui1.lmms.lmco.com
%
% dgleich
% 2003-11-19
% Added ability to pass a cell array of properties
%  2020-02-04
%  MM -- added different "matchtype" categories

if isempty(varargin)
   return; % No need to do anything.
end

if iscell(varargin{1})
   varargin = varargin{1};
end

% Parse matchtype from inputs
if isnumeric(varargin{1})
   matchtype = 0;
   varargin(1) = [];
else
   matchtype = 0;
end

% Check that number of inputs makes sense
nPropArgs = numel(varargin);
if mod(nPropArgs,2)~=0
   error(['nigeLab:' mfilename ':BadFormat'],...
      'Property names and values must be specified in pairs.');
end

% Based on matchtype, give "matching" function
prop_names = fieldnames(properties);
switch matchtype
   case 0
      matchFun = @(propStruct,toMatch,toAssign)matchCaseStrict(prop_names,propStruct,toMatch,toAssign);
   case 1
      matchFun = @(propStruct,toMatch,toAssign)matchStrict(prop_names,propStruct,toMatch,toAssign);
   case 2
      matchFun = @(propStruct,toMatch,toAssign)matchCaseSkip(prop_names,propStruct,toMatch,toAssign);
   case 3
      matchFun = @(propStruct,toMatch,toAssign)matchSkip(prop_names,propStruct,toMatch,toAssign);
   case 4
      matchFun = @(propStruct,toMatch,toAssign)matchCaseAssign(propStruct,toMatch,toAssign);
   case 5
      matchFun = @(propStruct,toMatch,toAssign)matchAssign(prop_names,propStruct,toMatch,toAssign);
   otherwise
      error(['nigeLab:' mfilename ':BadCase'],...
         '[GETOPT]: Invalid matchtype value: %g\n',matchtype);
end

for iProp=1:2:nPropArgs
   propName = varargin{iProp};
   if ~ischar(propName)
      error(['nigeLab:' mfilename ':BadClass'],...
         '[GETOPT]: Property names must be character strings.');
   end
   propVal = varargin{iProp+1};
   properties = matchFun(properties,propName,propVal);
   
end

% Different "matching" functions depend on matchtype case
   function propstruct = matchCaseStrict(allnames,propstruct,tomatch,toassign)
      %MATCHCASESTRICT  For matchtype 0, strictest (case-sensitive) match
      idx = strcmp(allnames, tomatch);
      if sum(idx)~=1 
         error(['nigeLab:' mfilename ':BadName'],...
            ['[GETOPT]: Invalid property ''',tomatch,'''; must be one of:'],...
            allnames{:});
      end
      propstruct.(tomatch) = toassign;
   end

   function propstruct = matchStrict(allnames,propstruct,tomatch,toassign)
      %MATCHSTRICT  For matchtype 1, stills throw error on
      %              (case-insensitive) mismatch
      idx = strcmpi(allnames, tomatch);
      if sum(idx)~=1 
         error(['nigeLab:' mfilename ':BadName'],...
            ['[GETOPT]: Invalid property ''',tomatch,'''; must be one of:'],...
            allnames{:});
      end
      propstruct.(allnames{idx}) = toassign;
   end

   function propstruct = matchCaseSkip(allnames,propstruct,tomatch,toassign)
      %MATCHCASESKIP  For matchtype 2, case-sensitive; skip if not there
      idx = strcmp(allnames, tomatch);
      if sum(idx)~=1 
         return;
      end
      propstruct.(tomatch) = toassign;
   end

   function propstruct = matchSkip(allnames,propstruct,tomatch,toassign)
      %MATCHCASESKIP  For matchtype 3, case-insensitive; skip if not there
      idx = strcmpi(allnames, tomatch);
      if sum(idx)~=1 
         return;
      end
      propstruct.(allnames{idx}) = toassign;
   end

   function propstruct = matchCaseAssign(propstruct,tomatch,toassign)
      %MATCHCASEASSIGN  For matchtype 4, case-sensitive; assign regardless
      propstruct.(tomatch) = toassign;
   end

function propstruct = matchAssign(allnames,propstruct,tomatch,toassign)
      %MATCHASSIGN  For matchtype 5, case-insensitive; assign regardless
      idx = strcmpi(allnames, tomatch);
      if sum(idx)~=1 
         propstruct.(tomatch) = toassign;
      else
         propstruct.(allnames{idx}) = toassign;
      end
   end

end