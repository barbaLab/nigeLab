function [p2pamp,ts,pmin,dt,E] = SNEOThreshold(data,pars,art_idx)
%% SNEOTHRESHOLD   Smoothed nonlinear energy operator thresholding detect
%
%  [p2pamp,ts,pmin,dt,E] = SNEOTHRESHOLD(data,pars,art_idx)
%
%   --------
%    INPUTS
%   --------
%     data      :       1 x N double of bandpass filtered data, preferrably
%                       with artifact excluded already, on which to perform
%                       monopolar spike detection.
%
%     pars      :       Parameters structure from SPIKEDETECTCLUSTER with
%                       the following fields:
%
%       -> SNEO_N    \\ number of samples for smoothing window
%       -> MULTCOEFF \\ factor to multiply NEO noise threshold by
%
%    art_idx   :        Indexing vector for artifact rejection periods,
%                       which are temporarily removed so that thresholds
%                       are not underestimated.
%
%   --------
%    OUTPUT
%   --------
%    p2pamp     :       Peak-to-peak amplitude of spikes.
%
%     ts        :       Timestamps (sample indices) of spike peaks.
%
%    pmin       :       Value at peak minimum. (pw) in SPIKEDETECTIONARRAY
%
%      dt       :       Time difference between spikes. (pp) in
%                       SPIKEDETECTIONARRAY
%
%      E        :       Smoothed nonlinear energy operator value at peaks.
%
% By: Max Murphy    1.0   01/04/2018   Original version (R2017a)

%% GET NONLINEAR ENERGY OPERATOR SIGNAL AND SMOOTH IT
Y = data - mean(data);
Yb = Y(1:(end-2));
Yf = Y(3:end);
Z = [0, Y(2:(end-1)).^2 - Yb .* Yf, 0]; % Discrete nonlinear energy operator
Zs = fastsmooth(Z,pars.SNEO_N);
clear('Z','Y','Yb','Yf');
%% CREATE THRESHOLD FILTER
tmpdata = data;
tmpdata(art_idx) = [];
tmpZ = Zs;
tmpZ(art_idx) = [];

th = pars.MULTCOEFF * median(abs(tmpZ));
data_th = pars.MULTCOEFF * median(abs(tmpdata));
clear('tmpZ','tmpdata');
%% PERFORM THRESHOLDING
pk = Zs > th;

if sum(pk) <= 1
   p2pamp = [];
   ts = [];
   pmin = [];
   dt = [];
   return
end

%% REDUCE CONSECUTIVE CROSSINGS TO SINGLE POINTS
z = zeros(size(data));
pkloc = repmat(find(pk),pars.NS_AROUND*2+1,1) + (-pars.NS_AROUND:pars.NS_AROUND).';
pkloc(pkloc < 1) = 1;
pkloc(pkloc > numel(data)) = numel(data);
pkloc = unique(pkloc(:));

z(pkloc) = data(pkloc);
[pmin,ts] = findpeaks(-z,... % Align to negative peak
               'MinPeakHeight',data_th);
E = Zs(ts);            


%% GET PEAK-TO-PEAK VALUES
tloc = repmat(ts,2*pars.PLP+1,1) + (-pars.PLP:pars.PLP).';
tloc(tloc < 1) = 1;
tloc(tloc > numel(data)) = numel(data);
pmax = max(data(tloc));

p2pamp = pmax + pmin;

%% EXCLUDE VALUES OF PMAX <= 0
pm_ex = pmax<=0;
ts(pm_ex) = [];
p2pamp(pm_ex) = [];
pmax(pm_ex) = [];
pmin(pm_ex) = [];
E(pm_ex) = [];

%% GET TIME DIFFERENCES
if numel(ts)>1
   dt = [diff(ts), round(median(diff(ts)))];
else
   dt = [];
end


end

function Y=fastsmooth(X,N,varargin)
%% FASTSMOOTH    Smooths vector X
%
%   Y = FASTSMOOTH(X,N)
%
%   Y = FASTSMOOTH(X,N,Type)
%
%   Y = FASTSMOOTH(X,N,Type,Ends)
%
%   Y = FASTSMOOTH(X,N,Type,Ends,Dim)
%
%	Example:
%   fastsmooth([1 1 1 10 10 10 1 1 1 1],3)= [0 1 4 7 10 7 4 1 1 0]
%   fastsmooth([1 1 1 10 10 10 1 1 1 1],3,1,1)= [1 1 4 7 10 7 4 1 1 1]
%
%   --------
%    INPUTS
%   --------
%      X        :       Vector with > N elements.
%
%      N        :       Window length (scalar, integer) for smoothing.
%                       Given as number of indices to smooth over.
%
%     Type      :       (Optional) Determines smooth type:
%                       - 'abs_med' (sliding-absolute-median)
%                       - 'med'  (sliding-median)
%                       - 'rect' (sliding-average/boxcar)
%                       - 'tri'  (def; 2-passes of sliding-average (f/b))
%                       - 'pg'   (4-passes of sliding-average (f/b/f/b))
%
%     Ends      :       (Optional) Controls the "ends" of the signal.
%                       (First N/2 points and last N/2 points).
%                       - 0 (sets ends to zero; fastest)
%                       - 1 (def; progressively smooths ends with shorter
%                            widths. can take a long time for long windows)
%
%     Dim      :        (Optional) If submitting a matrix, specifies
%                                   dimension to smooth (default: smooth 
%                                   dimensions with largest size). 
%                                   Specify as 1 to smooth rows.
%                                   Specify as 2 to smooth columns.
%
%   --------
%    OUTPUT
%   --------
%      Y        :       Smoothed (low-pass filtered) version of X. Degree
%                       of smoothing depends mostly on window length, and
%                       slightly on window type.
%
% Original version by: T. C. O'Haver, May, 2008. (v2.0)
%
% Adapted by: Max Murphy 10/11/2018 v5.0 Change so that 'tri' and 'pg'
%                                        attempt to mitigate phase offset
%                                        by alternating forward and reverse
%                                        sweeps. 'pg' changed to 4 sweeps.
%                        06/30/2018 v4.1 Added recursion to handle matrix
%                                        arrays.
%                        03/22/2018 v4.0 Added recursion to make it handle
%                                        cell arrays.
%                        03/14/2017 v3.0 Added argument parsing, changed
%                                        defaults, added documentation and
%                                        changed variable names for
%                                        clarity. (Matlab R2016b)
%                        12/28/2017 v3.1 Added "median" smoothing.

%% DEFAULTS
DEF_TYPE = 'tri';
DEF_ENDS = 1;
[~,DEF_DIM] = min(size(X)); % use "min" since it smoothes along that dim

TYPE_OPTS = {'med', 'abs_med', 'tri', 'rect', 'pg', 'gauss'};

%% VALIDATION FUNCTIONS
validateX = @(input) validateattributes(input,{'numeric','cell'},...
                        {'nonsparse','nonempty'},...
                        mfilename,'X');
                 
validateN = @(input) validateattributes(input, ...
                        {'numeric'}, ...
                        {'scalar','positive','integer'},...
                        mfilename,'N');
                 
validateType = @(input) any(validatestring(input,TYPE_OPTS));

validateEnds = @(input) isnumeric(input) && ...
                           isscalar(input) && ...
                           ((abs(input)<eps)||abs(input-1)<eps);

validateDim = @(input) isnumeric(input) && ...
                           isscalar(input) && ...
                           ((abs(input-1)<eps)||abs(input-2)<eps);
%% CHECK ARGUMENTS
p = inputParser;

addRequired(p,'X',validateX);
addRequired(p,'N',validateN);
addOptional(p,'Type',DEF_TYPE,validateType);
addOptional(p,'Ends',DEF_ENDS,validateEnds);
addOptional(p,'Dim',DEF_DIM,validateDim);

parse(p,X,N,varargin{:});

Type = p.Results.Type;
Ends = p.Results.Ends;
Dim = p.Results.Dim;

%% USE RECURSION IF X IS PASSED AS A CELL
if iscell(X)
   [d1,d2] = size(X);
   Y = cell(d1,d2);
   for i1 = 1:d1
      for i2 = 1:d2
         Y{i1,i2} = fastsmooth(X{i1,i2},N,Type,Ends);
      end
   end
   return;
elseif (size(X,1) > 1) && (size(X,2) > 1)
   
   [d1,d2] = size(X);
   Y = nan(d1,d2);
   switch Dim
      case 1
         for ii = 1:d1
            Y(ii,:) = fastsmooth(X(ii,:),N,Type,Ends);
         end
      case 2
         for ii = 1:d2
            Y(:,ii) = fastsmooth(X(:,ii),N,Type,Ends);
         end
   end
   return;
end

%% RUN DIFFERENT SUBFUNCTION DEPENDING ON SMOOTHING KERNEL FUNCTION
switch Type
   case 'abs_med'
      Y=med_smoother(abs(X),N,Ends);
   case 'med'
      Y=med_smoother(X,N,Ends);
   case 'rect'
      Y=smoother(X,N,Ends); % 1 - forward
   case 'tri'
      Y= rev_smoother(...             % 2 - back
         smoother(X,N,Ends),N,Ends);  % 1 - forward
   case {'pg', 'gauss'}
      Y=rev_smoother(...                             % 4 - back
         smoother(...                                % 3 - forward
         rev_smoother(...                            % 2 - back
         smoother(X,N,Ends),N,Ends),N,Ends),N,Ends); % 1 - forward
end

%% IMPLEMENT SMOOTHING
   function y=smoother(x,n,ends)
      % Actually implements the smoothing   
      SumPoints=nansum(x(1:n));
      s=zeros(size(x));
      halfw=round(n/2);
      L=numel(x);
      sx(isnan(x)) = 0;
      %%%%%%%%%%% changed by FB 11/13 idealy the same, more efficient
%       for k=1:L-n
%         s(k+halfw-1)=SumPoints;
%         SumPoints=nansum([SumPoints,-x(k)]);
%         SumPoints=nansum([SumPoints,x(k+n)]);
%       end
      s = [zeros(1,round(n/2)-1)  SumPoints+[0 cumsum(-x(1:end-n-1))]+[0 cumsum(x(n+1:end-1))] zeros(1,round(n/2)) ] ;
      SumPoints = SumPoints+sum(-x(1:end-n))+sum(x(n+1:end));
      
      
      s(L-n+halfw)=SumPoints; % So loop doesn't break
      y=s./n;

      % Taper the ends of the signal if ends=1.
      if ends==1
        startpoint=(n + 1)/2;
        y(1)=(x(1)+x(2))./2;
        for k=2:startpoint
            y(k)=nanmean(x(1:(2*k-1)));
            y(L-k+1)=nanmean(x(L-2*k+2:L));
        end
        y(L)=(x(L)+x(L-1))./2;
      end

   end

%% Function for "reverse" sliding average smoothing
    function y=rev_smoother(x,n,ends)
        y=fliplr( smoother ( fliplr(x), n, ends));

%       % Actually implements the smoothing   
%       SumPoints=nansum(x(end:-1:(end-n+1)));
%       s=zeros(size(x));
%       halfw=round(n/2);
%       L=numel(x);
%       for k=L:-1:(n+1)
%         s(k-halfw+1)=SumPoints;
%         SumPoints=nansum([SumPoints,-x(k)]);
%         SumPoints=nansum([SumPoints,x(k-n)]);
%       end
%       s(k-halfw)=SumPoints; % So loop doesn't break
%       y=s./n;
% 
%       % Taper the ends of the signal if ends=1.
%       if ends==1
%         startpoint=(n + 1)/2;
%         y(1)=(x(1)+x(2))./2;
%         for k=2:startpoint
%             y(k)=nanmean(x(1:(2*k-1)));
%             y(L-k+1)=nanmean(x(L-2*k+2:L));
%         end
%         y(L)=(x(L)+x(L-1))./2;
%       end

   end
 
   function y=med_smoother(x,n,ends)
      % Actually implements the smoothing   
      y=zeros(size(x));
      halfw=round(n/2);
      L=numel(x);
      for k=1:L-n
        y(k+halfw-1)=nanmedian(x(k:(k+n)));
      end

      % Taper the ends of the signal if ends=1.
      if ends==1
        startpoint=(n + 1)/2;
        y(1)=(x(1)+x(2))./2;
        for k=2:startpoint
            y(k)=nanmedian(x(1:(2*k-1)));
            y(L-k+1)=nanmedian(x(L-2*k+2:L));
        end
        y(L)=(x(L)+x(L-1))./2;
      end
    
    end

end


