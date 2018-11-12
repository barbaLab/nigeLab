function x_neo = mmNEO(x)
%% MMNEO    Nonlinear energy operator (NEO)
%
%  x_neo = MMNEO(x)
%
%  --------
%   INPUTS
%  --------
%     x     :     Input vector. If given as a matrix, returns NEO for each
%                 column (i.e. treats each row of a column as a new sample
%                 in the record through time).
%
%  --------
%   OUTPUT
%  --------
%   x_neo   :     Nonlinear energy operator (NEO) for input signal. Has
%                 same dimensions as input signal; 0 is appended to the
%                 first and last element since they cannot be computed.
%
% By: Max Murphy  v1.0  01/09/2018  Original version (R2017a)

%% 
[dim1,dim2] = size(x);
if ((dim1>1) && (dim2>1)) % For matrix, iterate over columns
   x_neo = nan(dim1,dim2);
   for ii = 1:dim2
      x_neo(:,ii) = compute_neo(x(:,ii));
   end   
else % For vector, return original shape
   x_neo = reshape(compute_neo(x),dim1,dim2);   
end

   % nonlinear energy operator: x(t)^2 - x(t-1)*x(t+1)
   function output = compute_neo(input)
      X = reshape(input - mean(input),numel(input),1);
   
      Xb = X(1:(end-2));
      Xf = X(3:end);
      X = X(2:(end-1));

      output = [0; X.^2 - Xb .* Xf; 0];       
   end

end