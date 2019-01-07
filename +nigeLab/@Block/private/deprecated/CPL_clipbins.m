function Xout = CPL_clipbins(Xin)
%% CPL_CLIPBINS   Clip all bin counts to 1
%
%  Xout = CPL_CLIPBINS(Xin);
%
%  --------
%   INPUTS
%  --------
%    Xin    :     Cell array, where each array element is a matrix where
%                 each column is a binned count of spikes at some time
%                 point relative to an alignment point.
%
%  --------
%   OUTPUT
%  --------
%    Xout   :     Identical to Xin, but max of any element is 1.
%
%  By: Max Murphy v1.0  03/14/2018  Original version (R2017b)

%% 
Xout = Xin;
for iX1 = 1:size(Xin,1)
   for iX2 = 1:size(Xin,2)
      Xout{iX1,iX2} = min(ones(size(Xin{iX1,iX2})),Xin{iX1,iX2});
   end
end
   
   


end