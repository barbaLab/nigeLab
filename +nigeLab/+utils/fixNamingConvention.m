function header_ = fixNamingConvention(header,delim)
% FIXNAMINGCONVENTION  Remove '_' and switch to CamelCase
%
%  header_ = nigeLab.utils.fixNamingConvention(header);
%  --> returns header_, a struct with proper naming conventions  
%
%  f = nigeLab.utils.fixNamingConvention('field_name');
%  --> returns 'FieldName'
%
%  header_ = nigeLab.utils.fixNamingConvention(header,delim);
%  --> Changes the delimiter used for extracting "word blocks"
%
%  Returns struct header_, which is identical to input struct header, but
%     with fieldnames named in convention used for Property names in
%     nigeLab.
%
%  If input argument "header" is a char array, then output "header_" is
%  simply the same char array with the fixed naming convention applied to
%  it, just as would be applied to all struct fields.

%%
if nargin < 2
   delim = '_';
end

switch class(header)
   case 'struct' % Actually probably is "header" struct
      header_ = struct;
      f = fieldnames(header);
      for iF = 1:numel(f)
         str = fixName(f{iF},delim);
         header_.(str) = header.(f{iF});
      end
      return;
      
   case 'char' % Could be any char array as well
      header_ = fixName(header,delim);
      return;
      
   case 'cell' % Could be a cell array of struct or char arrays (or mix)
      header_ = cell(size(header));
      for i = 1:numel(header)
         header_{i} = nigeLab.utils.fixNamingConvention(header{i},delim);
      end
      
      return;
   otherwise
      error('Unsupported input class: %s',class(header));
end

   function char_out = fixName(char_in,delim)
      % FIXNAME  Fixes naming convention for input character array by
      %          splitting all delimited char blocks, capitalizing the
      %          first letter of each delimited block element, then
      %          concatenating them back together using '' as the "joining"
      %          character.
      %
      %  char_out = fixName(char_in,delim);
      
      char_out = strsplit(char_in,delim);
      for iS = 1:numel(char_out)
         char_out{iS}(1) = upper(char_out{iS}(1));
      end
      char_out = strjoin(char_out,'');
      
   end
end