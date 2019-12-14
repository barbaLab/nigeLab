function out = getFirstNonEmptyCell(in,defVal)
%% GETFIRSTNONEMPTYCELL    out = utils.getFirstNonEmptyCell(in);
%
%  Returns value of first non-empty element of 'in'
%     (If no non-empty elements, returns an empty array; or, if 'defVal' is
%        specified, returns that value instead).

%% Check for alternative default value
if nargin < 2
   out = [];
else
   out = defVal;
end

%% Iterate on 'in'
i = 0;
while i < numel(in)
   i = i + 1;
   if ~isempty(in{i})
      out = in{i};
      break;
   end
end

end