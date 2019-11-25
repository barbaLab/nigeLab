function str = getNigeLink(className,methodName,linkText)
% GETNIGELINK  Returns html link string for a given class/method name
%
% Examples - 
%  str = nigeLab.utils.GETNIGELINK('nigeLab.utils.getHash');
%  str = nigeLab.utils.GETNIGELINK('nigeLab.libs.DiskData','subsasgn');
%  str = nigeLab.utils.GETNIGELINK(__,'string for link');
%%
% % Possibly add
%  str = nigeLab.utils.GETNIGELINK(__,struct('keepLeadingBracket',true,...
%                                            'keepTralingBracket',true));

%%
% if nargin < 4
%    opts = struct('keepLeadingBracket',true,...
%           'keepTralingBracket',true);
% end

if nargin < 2
   str_start = '<a href="matlab: opentoline(';
   fname = which(className);
   str = [str_start '''' fname ''', 1);"> '];
   
elseif nargin < 3
   str_start = '<a href="matlab: matlab.desktop.editor.openAndGoToFunction(';
   fname = which(className);
   str = [str_start '''' fname ''', ''' methodName ''');"> '];
else
   str_start = '<a href="matlab: matlab.desktop.editor.openAndGoToFunction(';
   fname = which(className);
   link_str = [str_start '''' fname ''', ''' methodName ''');'];
   help_str = [' help(''' className '/' methodName ''');">' linkText '</a>'];
   str = [link_str help_str];
end



end