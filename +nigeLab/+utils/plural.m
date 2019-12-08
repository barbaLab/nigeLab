function s = plural(n)
% PLURAL  Utility function to optionally pluralize words depending on 'n'
%
%  s = nigeLab.utils.plural(n)
%
% From: Intan-provided Matlab extraction code.

if (n == 1)
   s = '';
else
   s = 's';
end

end