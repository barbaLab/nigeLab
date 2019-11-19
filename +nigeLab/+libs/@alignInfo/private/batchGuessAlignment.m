function T_out = batchGuessAlignment(T_in,varargin)
%% BATCHGUESSALIGNMENT  Batch script to guess alignments (speed scoring)
%
%  T_out = BATCHGUESSALIGNMENT(T_in,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%    T_in      :  Matlab table with 2 columns: 'name' and 'rat'
%                 -> 'name' : recording block name
%
%                 -> 'rat' : unique rat identifier for the study
%
%  varargin    :  (Optional) 'NAME', value input argument pairs
%
%                    -> 'DIR' \\ location with 'rat' folders (TDT 'tanks')
%
%                    -> 'VID_DIR' \\ location with videos (and more
%                                    importantly, with DLC exported data
%                                    files)
%
%                    -> 'IN' \\ Beam-break Matlab file tag
%
%                    -> 'OUT' \\ Guess output Matlab file name (goes in
%                                same place as the IN file.
%
%                    -> 'OVERWRITE' \\ (def: false) Force overwrites old
%                                                   guesses.
%
%  --------
%   OUTPUT
%  --------
%    T_out     :     Matlab table with same variables as T_in, but only
%                    containing rows of recordings that had a new guess
%                    made.
%
% By: Max Murphy  v1.1  09/05/2018  (R2017b) - Updated from script to func

%% DEFAULTS
DIR = 'P:\Extracted_Data_To_Move\Rat\TDTRat'; % Location with rat folders
VID_DIR = 'K:\Rat\Video\BilateralReach\RC'; % Location with videos/DLC
DEF_FILE = 'Processing-List.mat'; % File containing default Table
IN = '_Beam.mat'; % Beam-break channel
OUT = '_Guess.mat'; % Append to make new file name
OVERWRITE = false;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% PARSE INPUT TABLE
if nargin < 1
   load(DEF_FILE,'T'); % T: Matlab table with 1 column: name
else
   T = T_in; clear T_in
end

%% LOOP THROUGH EVERY ROW OF T
vec = 1:size(T,1);
rmvec = [];
h = waitbar(0,'Please wait, estimating best alignment offsets...');
for iT = vec
   rat = T.rat{iT};
   block = T.name{iT};
   
   % Output from DeepLabCut is in csv format - find file
   F = dir(fullfile(VID_DIR,[block '*.csv']));
   if isempty(F)
      rmvec = [rmvec, iT]; %#ok<*AGROW>
      continue;
      
   elseif numel(F) > 1
      [~,idx] = max([F.bytes]); % Use largest file if multiple
      F = F(idx);
   end
   
   % Get pellet retrieval paw probability time-series for video
   vidTracking = importRC_Grasp(fullfile(VID_DIR,F.name));
   p = vidTracking.grasp_p;
   
   % Filename of beam-break file
   pname = fullfile(DIR,rat,block,[block '_Digital']);
   f_in = struct('folder',pname,'name',[block IN]);
   fname_out = fullfile(pname,[block OUT]);
   
   % Only do this if a guess doesn't already exist.
   if (exist(fname_out,'file')==0) || OVERWRITE
   
      % Try to make guess
      try
         alignGuess = makeAlignmentGuess(p,f_in);

         % Save guess to same location as beam-break series
         save(fname_out,'alignGuess','-v7.3');
      catch me
         rmvec = [rmvec, iT];
         disp(me.identifier);
         disp(me.message);
         stack = me.stack;
         mtb(stack);         
      end
   else
      rmvec = [rmvec, iT];
   end
   waitbar(iT/size(T,1));
end
delete(h);

%% RETURN OUTPUT
% Return only the table elements that actually had a new guess made
T_out = T(setdiff(vec,rmvec),:);


end
