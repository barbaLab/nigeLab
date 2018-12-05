function [byUnit,byTrial,tVec] = CPL_alignspikes(X,idx,varargin)
%% CPL_ALIGNSPIKES   Align spikes from array X using external alignment t
%
%    aligned = CPL_alignspikes(X,idx,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     X     :     Cell array of spike times, where each cell element is a
%                 series of "peak_train" sparse index vectors of where the
%                 spike peak occurred.
%
%                 Alternatively, cell array elements can just be non-sparse
%                 sample indexes at which spike peaks occurred.
%
%    idx    :     Alignment indexes.
%
%  varargin :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%   byUnit  :     Cell array where each array element contains a cell array
%                 of spike times representing a single unit on multiple
%                 trials.
%
%   byTrial :     Cell array in which each array element contains a cell
%                 array of spike times with each array element
%                 corresponding to the spike times of a given unit on a
%                 specific trial.
%
%     tVec  :     Bin centers (seconds) for each column of binned counts.
%
% By: Max Murphy  v1.0  03/12/2018  Original version (R2017b)

%% DEFAULTS
EXT      =   nan;    % External times, to sync to each alignment time
FS       = 30000;    % Sampling rate of record

E_PRE    = 1.000; 	% Epoch "pre" alignment (seconds)
E_POST   = 0.500;    % Epoch "post" alignment (seconds)
BINSIZE  = 0.025;    % Width of bins (seconds)

CLIP_BINS =false;    % Set true to clip bin counts to 1.
OUT_MODE  = 'ts';    % Can be 'ts' or 'bins'
                     % -> 'ts' (def) : return cell arrays of spike times
                     % -> 'bin'      : return binned matrices
                     
IDX_TYPE  = 'ts';    % Can be 'ts' or 'index'
                     % -> 'ts' (def) : alignments are times (seconds)
                     % -> 'index'    : alignments are 1-indexed integers

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if min(size(X)) > 1
   error('X must be an [Nx1] or [1xN] cell array.');
end

%% BOOKKEEPING SCALARS
nUnit = numel(X);
nTrial = numel(idx);

binVec = (-E_PRE):BINSIZE:(E_POST);     % Bins for alignment histogram
tVec = binVec(1:(end-1)) + (BINSIZE/2); % Put times as bin centers

T = numel(tVec);

for iX = 1:nUnit
   if issparse(X{iX})
      x = find(X{iX})./FS;
      X{iX} = reshape(x,1,numel(x));
   else
      x = X{iX}./FS;
      X{iX} = reshape(x,1,numel(x));
   end
end

if strcmpi(IDX_TYPE,'index') || strcmpi(IDX_TYPE,'idx')
   idx = idx./FS;
end

%% GET ALIGNMENT BY UNIT
byUnit = cell(nUnit,1);
for iUnit = 1:nUnit
   if strcmpi(OUT_MODE,'bin')
      clip_ok = true;
      byUnit{iUnit} = zeros(nTrial,T);
      for iTrial = 1:nTrial
         byUnit{iUnit}(iTrial,:) = histcounts(X{iUnit}-idx(iTrial),binVec);
      end
   else
      clip_ok = false;
      byUnit{iUnit} = cell(nTrial,1);
      for iTrial = 1:nTrial
         x = X{iUnit}-idx(iTrial);
         byUnit{iUnit}{iTrial} = x(x>=(-E_PRE) & x<= E_POST);
      end
   end
end

if CLIP_BINS && clip_ok
   byUnit = CPL_clipbins(byUnit);
end

%% GET ALIGNMENT ORGANIZED BY TRIAL
byTrial = cell(nTrial,1);
for iTrial = 1:nTrial
   if strcmpi(OUT_MODE,'bin')
      byTrial{iTrial} = zeros(nUnit,T);
      for iUnit = 1:nUnit
         byTrial{iTrial}(iUnit,:) = histcounts(X{iUnit}-idx(iTrial),binVec);
      end
   else
      byTrial{iTrial} = cell(nUnit,1);
      for iUnit = 1:nUnit
         x = X{iUnit}-idx(iTrial);
         byTrial{iTrial}{iUnit} = x(x>=(-E_PRE) & x<= E_POST);
      end
   end
end

if CLIP_BINS && clip_ok
   byTrial = CPL_clipbins(byTrial);
end

end