function short_str = shortenedName(name_str,maxChar)
%SHORTENEDNAME  Returns a shortened version of filename string (for
%                 display purposes only; not a valid filename probably)
%
%  Usage:
%  >> [p,f,e] = fileparts(nigelObj.File);
%  >> short_name = nigeLab.utils.shortenedName([f e]);
%  >> short_str = nigeLab.utils.shortenedPath(p);
%  >> disp([short_name short_str]);
%
%  >> short_str = nigeLab.utils.shortenedName(name_str,delim,maxChar);
%  name_str : char array of name to shorten
%  delim : Delimiter to split up "chunks" of name by
%  maxChar : (default: 16 chars) max number of chars to keep name intact
  
if nargin < 2
   delim = '_';
end

if nargin < 3
   maxChar = 16;
end

if numel(name_str) > maxChar
   nameParts = strsplit(name_str,delim);
   if numel(nameParts) > 1
      short_str = [nameParts{1} delim '...' delim nameParts{end}];
   else
      short_str = name_str;
   end
else
   short_str = name_str;
end

end