function data_ART = RemoveStimPeriods(data,pars)
%% REMOVESTIMPERIODS  Blanks data around stimulation time stamps
%
%   data_ART = REMOVESTIMPERIODS(data,pars)
%
% By: Max Murphy    v1.1    08/03/2017  Fixed bug due to single-precision
%                                       in lb and ub where indexing was
%                                       getting messed up.
%                   v1.0    08/01/2017  Original version (R2017a)

%% LOOP THROUGH STIM TIMES AND "ZERO" THEM OUT
% Create time-indexing vector
stim_index = pars.STIM_TS*pars.FS;
pre_stim = (pars.PRE_STIM_BLANKING*1e-3)*pars.FS;
post_stim = (pars.POST_STIM_BLANKING*1e-3)*pars.FS;

% Get pairs of lower- and upper-bounds for indexing
lb = double(max(round(stim_index - pre_stim),1));
ub = double(min(numel(data),round(stim_index + post_stim)));

iblank = []; % Accumulate indices

for iS = 1:numel(stim_index)
    iblank = [iblank, lb(iS):ub(iS)];
end

% Blank those indices
data_ART = data;
data_ART(iblank) = 0;


end