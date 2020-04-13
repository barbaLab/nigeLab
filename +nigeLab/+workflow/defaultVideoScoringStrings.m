function str = defaultVideoScoringStrings(Type,scoredVal)
%DEFAULTVIDEOSCORINGSTRINGS  Default function that returns a string based
%     on the value of 'Type' property.
%
%  str = defaultVideoScoringStrings(Type,scoredVal);
%
%  Inputs:
%     Type  --  Integer value from nigeLab.defaults.Video('VarType')
%     scoredVal -- Value passed from scoring interface for a particular
%                    variable based on pressing a 'hotKey'
%
%  See also:
%  nigeLab.defaults.Event, nigeLab.defaults.Video


switch Type
   case 5 % Currently, which paw was used for the trial
      if isnan(scoredVal)
         str = 'Unscored';
      else
         if scoredVal > 0
            str = 'Right';
         else
            str = 'Left';
         end
      end
      
   case 4 % Currently, outcome of the pellet retrieval attempt
      if isnan(scoredVal)
         str = 'Unscored';
      else
         if scoredVal > 0
            str = 'Successful';
         else
            str = 'Unsuccessful';
         end
      end
      
   case 3 % Currently, presence of pellet in front of rat
      if isnan(scoredVal)
         str = 'Unscored';
      else
         if scoredVal > 0
            str = 'Yes';
         else
            str = 'No';
         end
      end
      
   case 2 % Currently, # of pellets on platform
      if isnan(scoredVal)
         str = 'Unscored';
      else
         if scoredVal > 8
            str = '9+';
         else
            str = num2str(scoredVal);
         end
      end
      
   case 1
      if isnan(scoredVal)
         str = 'Unscored';
      elseif isinf(scoredVal)
         str = 'N/A';
      else
         str = num2str(scoredVal);
      end
      
   case 0
      if isnan(scoredVal)
         str = 'Unscored';
      elseif isinf(scoredVal)
         str = 'N/A';
      else
         str = num2str(scoredVal);
      end
   otherwise
      warning(['nigeLab:' mfilename ':BadConfig'],...
         ['Make a copy of this function and then modify the ' ...
         'switch ... case statement to accomodate your new VarType']);
      str_Type = nigeLab.utils.getNigeLink('nigeLab.defaults.Video',...
         'setScoringVars');
      str_fcn = nigeLab.utils.getNigeLink('nigeLab.defaults.Video',182,...
         'pars.VideoScoringStringsFcn');
      fprintf(1,'\n\t-->\tCheck %s <--\n',str_Type);
      fprintf(1,'\t*** Make sure to also change %s ***\n',str_fcn);
      error(['nigeLab:' mfilename ':BadConfig'],...
         'Strings function not designed for VarType: %g',Type);
end
end