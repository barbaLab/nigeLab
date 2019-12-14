function str = defaultVideoScoringStrings(obj,varType,scoredVal)
% DEFAULTVIDEOSCORINGSTRINGS  Default function that returns a string based
%     on the value of 'varType' property.
%
%  str = obj.defaultVideoScoringStrings(varType,scoredVal);
%
%  Inputs:
%     varType  --  Integer value from nigeLab.defaults.Video('VarType')
%     scoredVal -- Value passed from scoring interface for a particular
%                    variable based on pressing a 'hotKey'
%
%  See also:
%  nigeLab.defaults.Event, nigeLab.defaults.Video

%%
switch varType
   case 5 % Currently, which paw was used for the trial
      if scoredVal > 0
         str = 'Right';
      else
         str = 'Left';
      end
      
   case 4 % Currently, outcome of the pellet retrieval attempt
      if scoredVal > 0
         str = 'Successful';
      else
         str = 'Unsuccessful';
      end
      
   case 3 % Currently, presence of pellet in front of rat
      if scoredVal > 0
         str = 'Yes';
      else
         str = 'No';
      end
      
   case 2 % Currently, # of pellets on platform
      if scoredVal > 8
         str = '9+';
      else
         str = num2str(scoredVal);
      end
      
   case 1
      % Already in video time: set to neural time for display
      str = num2str(obj.toNeuTime(scoredVal));
      
   case 0
      % Already in video time: set to neural time for display
      str = num2str(obj.toNeuTime(scoredVal));
      
   otherwise
      warning(['Make a copy of this function and then modify the ' ...
         'switch ... case statement to accomodate your new VarType']);
      str_varType = nigeLab.utils.getNigeLink('nigeLab.defaults.Video',...
         'setScoringVars');
      str_fcn = nigeLab.utils.getNigeLink('nigeLab.defaults.Video',182,...
         'pars.VideoScoringStringsFcn');
      fprintf(1,'\n\t-->\tCheck %s <--\n',str_varType);
      fprintf(1,'\t*** Make sure to also change %s ***\n',str_fcn);
      error('Strings function not designed for VarType: %g',varType);
end
end