function varState = defaultForceToZeroFcn(obj)
%DEFAULTFORCETOZEROFCN  Function that forces all values for a given Trial
%                        to zero. This is mostly useful in combination with
%                        'ScoringShortcuts' that force all values to zero
%                        or inf if something is missing, for example, if
%                        there is no "reach" or whatever.
%
%  varState = obj.defaultForceToZeroFcn;
%
%  See also:
%  nigeLab.defaults.Video

varState = true(size(obj.VariableIndex));
for i = 1:numel(obj.VariableIndex)
   k = obj.VariableIndex(i);
   
   % Always set value to input value
   switch obj.Type(k)
      case 0 % Trial "onset" guess
         varState(i) = false; % something is wrong
      case 1 % Timestamps
         obj.Value(k) = inf;
         varState(i) = true;
      case 2 % Counts
         obj.Value(k) = 0;
         varState(i) = true;
      case 3 % No (0) or Yes (1)
         obj.Value(k) = 0;
         varState(i) = true;
      case 4 % Unsuccessful (0) or Successful (1)
         obj.Value(k) = 0;
         varState(i) = true;
      case 5 % Left (0) or Right (1)
         obj.Value(k) = inf;
         varState(i) = false; % something is wrong
      otherwise
         warning(['Make a copy of this function and then modify the ' ...
                  'switch ... case statement to accomodate your new VarType']);
               str_Type = nigeLab.utils.getNigeLink('nigeLab.defaults.Video','setScoringVars');
               str_fcn = nigeLab.utils.getNigeLink('nigeLab.defaults.Video',183,'pars.ForceToZeroFcn');
               fprintf(1,'\n\t-->\tCheck %s <--\n',str_Type);
               fprintf(1,'\t*** Make sure to also change %s ***\n',str_fcn);
               error('Strings function not designed for VarType: %g',obj.Type(k));
   end
end