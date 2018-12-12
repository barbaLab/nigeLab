function rhs_sites = RHD2RHS(rhd_sites,ntotal)
%% RHD2RHS  Convert RHD custom electrode layout site # to RHS
%
%  rhs_sites = RHD2RHS(rhd_sites,ntotal)
%
%  --------
%   INPUTS
%  --------
%  rhd_sites      :     (vector or matrix) RHD electrode site numbers.
%
%  ntotal         :     (scalar) Total number of sites (16 or 32)
%
%  --------
%   OUTPUT
%  --------
%  rhs_sites      :     (vector) Corresponding RHS electrode site numbers.
%
% By: Max Murphy  v1.0  07/22/2018  Original version (R2017b)

%% LAYOUTS
RHS_EQUIVALENT = [24:31, 0:23];

%% PARSE INPUT
if ~((abs(ntotal-32)<eps) || (abs(ntotal-16)<eps))
   error('Invalid ntotal (%d). Must be 16 or 32 channel array.',ntotal);
end

rhs_sites = nan(size(rhd_sites));
for iRow = 1:size(rhd_sites,1)
   for iCol = 1:size(rhd_sites,2)
      if isnan(rhd_sites(iRow,iCol)) % Skip NaN entries
         continue;
      else
         val = rhd_sites(iRow,iCol);
      end
      idx = val + 1;
      rhs_sites(iRow,iCol) = RHS_EQUIVALENT(idx);      
   end
end
   

end