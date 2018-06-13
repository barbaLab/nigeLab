function List(obj,name)
%% LIST  Give list of current files associated with field.
%
%  obj.LIST;
%  obj.LIST(name);
%
%  Note: If called without an input argument, returns names of all
%  associated files for all fields.
%
%  -------
%   INPUT
%  -------
%    name   :  Name of a particular field you want to return a
%              list of files for.
%
% By: Max Murphy  v1.0  06/13/2018 Original Version (R2017a)

%% RETURN LIST OF VALUES
if nargin == 2
   if isempty(obj.(name).dir)
      fprintf(1,'\nNo %s files found for %s.\n',name,obj.Name);
   else
      fprintf(1,'\nCurrent %s files stored in %s:\n->\t%s\n\n',...
         name, obj.Name, ...
         strjoin({obj.(name).dir.name},'\n->\t'));
   end
else
   for iL = 1:numel(obj.Fields)
      name = obj.Fields{iL};
      if isempty(obj.(name).dir)
         fprintf(1,'\nNo %s files found for %s.\n',name,obj.Name);
      else
         fprintf(1,'\nCurrent %s files stored in %s:\n->\t%s\n\n',...
            name, obj.Name, ...
            strjoin({obj.(name).dir.name},'\n->\t'));
      end
   end
end
end