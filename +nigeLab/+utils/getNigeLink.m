function str = getNigeLink(className,methodName,linkText)
% GETNIGELINK  Returns html link string for a given class/method name. The
%  link string can be used in combination with fprintf, but doesn't work
%  very well with nigeLab.utils.cprintf.
%
%  If the string is used via fprintf (e.g. fprintf(1,'-->\t%s\n,str)), then
%  clicking the output link in the Command Window jumps to the
%  corresponding file line or function in the Matlab editor. It also
%  outputs a call to the HELP function in the Command Window. If
%  'methodName' is a private function of 'className' (for example a
%  sub-function written within another function), then this is detected and
%  the top-level HELP is returned for 'className' instead.
%
% Examples: 
%  str = nigeLab.utils.GETNIGELINK('nigeLab.utils.makeHash');
%  --> Returns string with link to line 1 of 'makeHash' function. Link text
%      is 'nigeLab.utils.makeHash' in this case.
%
%  str = nigeLab.utils.GETNIGELINK('nigeLab.libs.DiskData','subsasgn');
%  --> Returns string with link to method 'subsasgn' of 'DiskData' class.
%      Link text is 'nigeLab.libs.DiskData/subsasgn' in this case.
%
%  str = nigeLab.utlis.GETNIGELINK('nigeLab.libs.DiskData', 25); 
%  --> Returns string with link to line 25 of nigeLab.libs.DiskData. Link
%      text is 'nigeLab.libs.DiskData' in this case.
%
%  str = nigeLab.utils.GETNIGELINK(__,'string for link');
%  --> Third argument can be used to specify the string that will be
%        displayed in the command window (not just the link string).

%% 
switch nargin
   case 1 % If only 1 input, just open to line 1 by default
      linkText = className;
      str_start = '<a href="matlab: opentoline(';
      fname = which(className);
      link_str = [str_start '''' fname ''', 1);'];
      help_str = [' help(''' className ''');">' linkText '</a>'];
      str = [link_str help_str];
   
   case 2 % If 2 inputs, determine if second is char or numeric
          %    Correspondingly, either link to function or specific line
      if ischar(methodName)
         linkText = [className '/' methodName];
         str_start = '<a href="matlab: matlab.desktop.editor.openAndGoToFunction(';
         fname = which(className);
         link_str = [str_start '''' fname ''', ''' methodName ''');'];
         tmp = help([className '/' methodName]);
         if isempty(tmp)
            help_str = [' help(''' className ''');">' linkText '</a>'];
         else
            help_str = [' help(''' className '/' methodName ''');">' linkText '</a>'];
         end
         str = [link_str help_str];
      elseif isnumeric(methodName)
         linkText = className;
         str_start = '<a href="matlab: opentoline(';
         fname = which(className);
         link_str = [str_start '''' fname ''', ' num2str(methodName) ');'];
         help_str = [' help(''' className ''');">' linkText '</a>'];
         str = [link_str help_str];
      else
         error('Bad class of methodName input: %s',class(methodName));
      end
   case 3 % If 3 inputs, same as case with 2, except there is an additional
          %    part of the "help_str" that includes the text to be
          %    superimposed for the link. 
      if ischar(methodName)
         str_start = '<a href="matlab: matlab.desktop.editor.openAndGoToFunction(';
         fname = which(className);
         link_str = [str_start '''' fname ''', ''' methodName ''');'];
         tmp = help([className '/' methodName]);
         if isempty(tmp)
            help_str = [' help(''' className ''');">' linkText '</a>'];
         else
            help_str = [' help(''' className '/' methodName ''');">' linkText '</a>'];
         end
         str = [link_str help_str];
      elseif isnumeric(methodName)
         str_start = '<a href="matlab: opentoline(';
         fname = which(className);
         link_str = [str_start '''' fname ''', ' num2str(methodName) ');'];
         help_str = [' help(''' className ''');">' linkText '</a>'];
         str = [link_str help_str];
      else
         error('Bad class of methodName input: %s',class(methodName));
      end   
   otherwise
      error('Invalid number of arguments (%g).',nargin);      
end

str = strrep(str,'\','/');

end