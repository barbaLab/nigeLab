function setProp(tankObj,varargin)
% SETPROP  Sets property of all tanks in array to a value
%
%  Uses <'Name', value> pairs to identify the property name.
%
%  setProp(tankObj,'prname',PrVal);
%  --> Set the name of a property without matching case
%
%  setProp(tankObj,'PrNameStruct.Field1.Field2',PrVal);
%  --> Set individual struct field property without resetting the
%        whole struct.
%     (Up to 2 fields "deep" max., to avoid using eval syntax)
%
%  tankObj.setProp('PrName1',PrVal1,'PrName2',PrVal2,...);
%  --> Set multiple property values at once
%
%  setProp(tankObjArray,'PrName1',PrVal1,'PrName2',PrVal2,...);
%  --> Set multiple properties of multiple Tanks at once

if isempty(tankObj)
   return;
end

% Allow multiple properties to be set at once, for multiple tanks
if numel(varargin) > 2
   for iV = 1:2:numel(varargin)
      setProp(tankObj,varargin{iV},varargin{iV+1});
   end
   return;
elseif numel(varargin) < 2
   error(['nigeLab:' mfilename ':TooFewInputs'],...
      'Not enough inputs to `setProp` (gave %g, need 3)',nargin);
else % numel(varargin) == 2
   if numel(tankObj) > 1
      for i = 1:numel(tankObj)
         setProp(tankObj(i),varargin{1},varargin{2});
      end
      return;
   end
   
   if ~ischar(varargin{1})
      error(['nigeLab:' mfilename ':BadInputType'],...
         'Expected input 2 to be char but got %s instead.',...
         class(varargin{1}));
   end
   propVal = varargin{2};
   propField = strsplit(varargin{1},'.');
   propName = propField{1};
   propField(1) = []; % Drop the first cell in array
   % If it is now empty, we were not trying to set a struct field
end

% Parse case-sensitivity on property
mc = metaclass(tankObj);
propList = {mc.PropertyList.Name};
idx = ismember(lower(propList),lower(propName));
if sum(idx) < 1
   nigeLab.utils.cprintf('Comments','No TANK property: %s',propName);
   return;
elseif sum(idx) > 1
   idx = ismember(propList,propName);
   if sum(idx) < 1
      nigeLab.utils.cprintf('Comments','No TANK property: %s',propName);
      return;
   elseif sum(idx) > 1
      error(['nigeLab:' mfilename ':AmbiguousPropertyName'],...
         ['Bad nigeLab.Tank Property naming convention.\n'...
         'Avoid Property names that have case-sensitivity.\n'...
         '->\tIn this case ''%s'' vs ''%s'' <-\n'],propList{idx});
   end
end
thisProp = propList{idx};

% Last, assignment depends on if 'field' values were requested
switch numel(propField)
   case 0
      % Does some validation, in case properties were read
      % directly from a text file for example; but not an
      % extensive amount.
      if isnumeric(tankObj.(thisProp)) && ischar(propVal)
         tankObj.(thisProp) = str2double(propVal);
      elseif iscell(tankObj.(thisProp)) && ischar(propVal)
         tankObj.(thisProp) = {propVal};
      else
         tankObj.(thisProp) = propVal;
      end
      
   case 1
      a = propField{1};
      if isfield(tankObj.(thisProp),a)
         if isnumeric(tankObj.(thisProp).(a)) && ischar(propVal)
            tankObj.(thisProp).(a) = str2double(propVal);
         elseif iscell(tankObj.(thisProp).(a)) && ischar(propVal)
            tankObj.(thisProp).(a) = {propVal};
         else
            tankObj.(thisProp).(a) = propVal;
         end
      else
         tankObj.(thisProp).(a) = propVal;
      end
      
   case 2
      a = propField{1};
      b = propField{2};
      if isfield(tankObj.(thisProp),a)
         if isfield(tankObj.(thisProp).(a),b)
            if isnumeric(tankObj.(thisProp).(a).(b)) && ischar(propVal)
               tankObj.(thisProp).(a).(b) = str2double(propVal);
            elseif iscell(tankObj.(thisProp).(a).(b)) && ischar(propVal)
               tankObj.(thisProp).(a).(b) = {propVal};
            else
               tankObj.(thisProp).(a).(b) = propVal;
            end
         else
            tankObj.(thisProp).(a).(b) = propVal;
         end
      else
         tankObj.(thisProp).(a).(b) = propVal;
      end
      
   otherwise
      % Shouldn't have more than 3 fields (could use eval here,
      % but prefer to avoid eval whenever possible).
      error(['nigeLab:' mfilename ':TooManyStructFields'],...
         ['Too many ''.'' delimited fields.\n' ...
         'Max 2 ''.'' for struct Properties.']);
end
end