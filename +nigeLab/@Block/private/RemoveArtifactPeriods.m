function [data_ART,art_idx] = RemoveArtifactPeriods(data,t_art)
%% REMOVEARTIFACTPERIODS  Remove pre-defined artifact periods.
%
%   data_ART = REMOVEARTIFACTPERIODS(data,pars)
%
%   --------
%    INPUTS
%   --------
%     data      :       1 x N vector of sample data
%
%     t_art     :       A 2 x K matrix of sample indexes, with the top row
%                       containing the start and bottom row containing the
%                       stop index for epochs to be blanked.
%
%   --------
%    OUTPUT
%   --------
%   data_ART    :       data, with the pre-specified epochs in
%                       pars.ARTIFACT blanked (set to zero).
%
%    art_idx    :       Indices that have been blanked from data.
%
% By: Max Murphy    v1.0    08/01/2017  Original version (R2017a)
%                   v1.1    07/27/2018  Added "art_idx" output so that the
%                                       "blanked" data can still be used
%                                       for automatic threshold generation,
%                                       by temporarily removing the part
%                                       that is all zeros (which can cause
%                                       the true threshold to be
%                                       underestimated).

%% LOOP AND CREATE BLANKING INDEX
art_idx = [];
for k = 1:size(t_art,2)
    art_idx = [art_idx, t_art(1,k):t_art(2,k)]; %#ok<AGROW>
end

%% SET ARTIFACT PERIODS TO ZERO
data_ART = data;
data_ART(art_idx) = 0;

end