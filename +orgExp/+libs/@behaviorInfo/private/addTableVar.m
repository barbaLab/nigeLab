function T = addTableVar(T,fieldName,colIdx,value)
%% ADDTABLEVAR    Append a variable (column) to a table with optional values
%
%  T = ADDTABLEVAR(T,fieldName);
%  T = ADDTABLEVAR(T,fieldName,value);
%
%  --------
%   INPUTS
%  --------
%     T        :     Matlab Table (N rows by M columns)
%
%  fieldName   :     (String) name of variable name to add to table.
%                    or (cell array of strings) names of variables to add
%                    to table.
%
%  colIdx      :     (Optional) Scalar specifying the column where this
%                                variable is to be inserted. For example, a
%                                table with 6 rows would normally append
%                                the column as the 7th. However, if colIdx
%                                is specified as 5, then the 5th column is
%                                the new variable and column 6 is the
%                                previous column from column 5 (so there
%                                are still 7 columns). If fieldName is a
%                                cell array of strings, then colIdx must
%                                match the number of elements of fieldName.
%
%  value       :     (Optional) N x 1 vector of values to use for the
%                                appended variable. By default if this is
%                                not specified, the value is set to NaN for
%                                each added variable. If a cell array of
%                                strings is specified for fieldName, then
%                                this should be an N x K matrix of values,
%                                where K is the number of cell elements
%                                added.
%
%  --------
%   OUTPUT
%  --------
%     T        :     Same as input but with additional variable columns.
%
% By: Max Murphy  v1.0  Original version (R2017b) 09/08/2018

%% PARSE INPUT
if nargin < 2 % If no fieldName specified, give default name and warn user
   fieldName = {'addedVar'};
   warning('No fieldName specified. Setting new variable name to addedVar.');
   
else % Otherwise make sure it's a cell
   if ~iscell(fieldName)
      fieldName = {fieldName};
   end
end

if nargin < 3 % By default, set index to add as the end
   vec = 1:(numel(fieldName) + size(T,2));
   
else
   if numel(colIdx) ~= numel(fieldName)
      error('Dimension mismatch between colIdx and fieldName inputs.');
   end
   
   vec = 1:size(T,2);
   insert = (1:numel(fieldName)) + size(T,2);
   for ii = 1:numel(fieldName)
      vec = [vec(1:(colIdx(ii)-1)), insert(ii), vec(colIdx(ii):end)];
   end
end

if nargin < 4 % Default values are NaN
   value = nan(size(T,1),numel(fieldName));
else
   if size(T,1) ~= size(value,1)
      error('Dimension mismatch between number of table rows and rows of value input.');
   end
   
   if numel(fieldName) ~= size(value,2)
      error('Dimension mismatch between number of fieldName inputs and number of value inputs.');
   end
   
end

%% LOOP THROUGH FIELDNAME ELEMENTS AND ADD TO TABLE
for ii = 1:numel(fieldName)
   T = [T, table(value(:,ii),'VariableNames',fieldName(ii))]; %#ok<AGROW>
end

%% RE-ORDER VARIABLES TO CORRECT ORDER
T = T(:,vec);

end