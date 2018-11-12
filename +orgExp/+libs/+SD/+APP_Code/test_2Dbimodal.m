function s = test_2Dbimodal(X,varargin)
%% TEST_2DBIMODAL   Check for bimodality with respect to elements of X
%
%   p = TEST_2DBIMODAL(X)
%
%   --------
%    INPUTS
%   --------
%      X        :       N x 2 matrix of observations, where each row is an
%                       observation and each column is a variable.
%
%   varargin    :       (Optional) 'NAME',value input argument pairs.
%
%       ->  'PLOT'  //  (default: 'off') Set to 'on' to show plots.
%
%   --------
%    OUTPUT
%   --------
%      s        :       "Surprise" score for coming from a uni-modal
%                       distribution. Higher values indicate greater
%                       surprise that the observed data in X come from a
%                       single distribution, based on the assumption of a
%                       bivariate normal distribution.
%
% By: Max Murphy    v1.0    08/07/2017  Original version (R2017a)
%   See also: WHITENROWS

%% DEFAULTS
PLOT = 'off';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% WHITEN DATA
X = whitenRows(X.').';

%% PLOT DATA
if strcmpi(PLOT,'on')
    scatter(X(:,1),X(:,2),5,'filled',...
        'MarkerFaceColor',[0.3 0.3 0.6],...
        'MarkerEdgeColor','none');
end

s = nan;

end