function qBatch(func_str,block,pre_align,post_align)
%% QBATCH   Script space for doing batch runs
%
%  QBATCH(func_str);
%  QBATCH(func_str,pre_align);
%  QBATCH(func_str,pre_align,post_align);
%
%  --------
%   INPUTS
%  --------
%  func_str    :     String referencing function that will be used to get
%                    alignment times to do spike detection on only snippets
%                    around epochs of interest.
%
%  block       :     Struct array containing all the recording BLOCKS to
%                    run through.
%
%  pre_align   :     (Optional; def: 2 seconds) Amount of time prior to the
%                       alignment to include in each epoch.
%
%  post_align  :     (Optional: def: 1 second) Amount of time after each
%                       alignment to include in each epoch.
%
%  --------
%   OUTPUT
%  --------
%  Does spike detection on series of epochs excluding a majority of the
%  recording. Can be useful to mitigate lots of noisy activity that isn't
%  specific to behavior of interest, and which causes clustering to behave
%  poorly.
%
% By: Max Murphy  v1.0   09/04/2018    Original version (R2017b)

%% DEFAULTS
E_PRE = 2.000;
E_POST = 1.000;
FS = 24414.0625;

%% PARSE INPUT
addpath('adhoc_detect');

if exist('pre_align','var')==0
   pre_align = E_PRE;
end

if exist('post_align','var')==0
   post_align = E_POST;
end

%% LOOP ON STRUCT AND QUEUE SPIKE DETECTION
TIC = tic;
for ii = 1:numel(block)
   
   eval(sprintf('[ts,b,tFinal] = %s(block(ii));',func_str));
   
   if isempty(ts)
      continue;
   elseif isnan(ts(1))
      continue;
   end
   
   ts((ts - pre_align) <= 0) = []; %#ok<*AGROW>
   ts((ts + post_align) >= tFinal) = [];   
   
   t_art = [1; ts(1)-pre_align];
   for iT = 2:numel(ts)
      t_add = [(ts(iT-1)+post_align); (ts(iT)-pre_align)];
      t_art = [t_art, t_add]; 
   end
   t_add = [(ts(end)+post_align); tFinal];
   t_art = [t_art, t_add]; 
   
   t_art = round(t_art * FS);
   
   % And submit the job for spike detection:
   qSD('DIR',b,'ARTIFACT',t_art,'TIC',TIC,'DELETE_OLD_PATH',true);
   
end
toc(TIC);

end