function short_str = shortenedPath(path_str)
%SHORTENEDPATH  Returns a shortened version of path file string (for
%                 display purposes only; not a valid file path)
%
%  Usage:
%  >> [p,f,e] = fileparts(nigelObj.File);
%  >> short_name = nigeLab.utils.shortenedName([f e]);
%  >> short_str = nigeLab.utils.shortenedPath(p);
%  >> disp([short_name short_str]);

path_str = nigeLab.utils.getUNCPath(path_str);
p = strrep(path_str,'\','/');
fParts = strsplit(p,'/');
if numel(fParts) > 1
   switch numel(fParts)
      case 2
         short_str=['//' fParts{2} '/'];
      case 3
         short_str=['//' fParts{2} '/' fParts{3}  '/'];
      otherwise
         short_str=['//' fParts{2} '/' fParts{3} '/.../' fParts{end} '/'];
   end
else
   short_str=path_str;
end

end