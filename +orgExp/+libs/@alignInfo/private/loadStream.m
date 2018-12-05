function stream_struct = loadStream(F)
%% LOADSTREAM    Load digital stream file for beam or pellet breaks
%
%  stream_struct = LOADSTREAM(F);
%
%  --------
%   INPUTS
%  --------
%  filename       :     File struct (from 'dir') for a given file.
%
%  --------
%   OUTPUT
%  --------
%  stream_struct  :     Struct with fields for 'data', 'fs', and 't'.
%
% By: Max Murphy  v1.0   08/27/2018  Original version (R2017b)

%% CHECK FOR FILE EXISTENCE
fname = fullfile(F.folder,F.name);
if exist(fname,'file') == 0
   fprintf(1,'->\t%s not found.\n',F.name);
   stream_struct = nan;
   return;
end

%% LOAD FILE
stream_struct = load(fname,'data','fs');
            
%% DERIVE OTHER VARIABLES
% Get time vector         
stream_struct.t = linspace(0,...
            (numel(stream_struct.data)-1)/stream_struct.fs,...
             numel(stream_struct.data));
          
% Make copy of time vector for "t0" version that doesn't get shifted
stream_struct.t0 = stream_struct.t;
          
%% DO NORMALIZATION
% Remove DC bias
stream_struct.data = stream_struct.data - min(stream_struct.data);

% Normalize between 0 and 1
stream_struct.data = stream_struct.data ./ max(stream_struct.data);


end