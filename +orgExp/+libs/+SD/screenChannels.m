function screenChannels(F,varargin)
%% SCREENCHANNELS    Loop and screen filtered traces for a recording set
%
%  SCREENCHANNELS(F)
%  SCREENCHANNELS(F,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     F        :     Struct obtained by calling 'dir' function on a
%                    directory that contains a set of recording blocks of
%                    interest. Should contain all the recording blocks that
%                    you want to remove the same probe number and channel
%                    number from.
%
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Pauses on figures of channels before closing them, so you can get an
%  idea of which channels should be removed from a given dataset. Figures
%  are saved with 'TAG' optional parameter appended to them, in the
%  recording BLOCK folder.
%
% By: Max Murphy  v1.0  08/17/2018  Original version (R2017a)

%% DEFAULTS
PLOT_TYPE = nan; % ('RawData' // 'Filtered' // 'FilteredCAR')
PAUSE_TIMER = 1; % Seconds

LEN = 0.25;
OFFSET = 200;
TAG = 'Channel_Screening';


%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% LOOP THROUGH AND PLOT CHANNELS FOR ALL BLOCKS IN STRUCT
for iF = 1:numel(F)
   
   [DIR,~] = get_path_to_channels(F(iF).folder,F(iF).name,PLOT_TYPE);
   
   try
      plotChannels('DIR',DIR,...
         'OFFSET',OFFSET,...
         'LEN',LEN,...
         'TAG',TAG,...
         'CHECK_FOR_SPIKES',false);
      pause(PAUSE_TIMER);
      delete(gcf);
   catch
      disp(['Unable to plot channels for ' F(iF).name]);
      delete(gcf);
   end
end

%% SUB-FUNCTIONS

   % Determine the best folder to plot, if no type is specified
   function [DIR,plot_type] = get_path_to_channels(folder,name,ptype)
      if isnan(ptype(1))
         plot_type = 'FilteredCAR';
         DIR = fullfile(folder,name,[name '_' plot_type]);
         if exist(DIR,'dir')==0
            plot_type = 'Filtered';
            DIR = fullfile(folder,name,[name '_' plot_type]);
            if exist(DIR,'dir')==0
               plot_type = 'Raw';
               DIR = fullfile(folder,name,[name '_' plot_type]);
            end
         end
      else
         plot_type = ptype;
         DIR = fullfile(folder,name,[name '_' plot_type]);
      end
   end


end