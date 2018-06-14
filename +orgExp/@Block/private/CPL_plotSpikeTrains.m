function CPL_plotSpikeTrains(behaviorData,varargin)
%% CPL_PLOTSPIKETRAINS  Plot all rasters for spike trains in a given BLOCK
%
%  CPL_PLOTSPIKETRAINS(behaviorData);
%  CPL_PLOTSPIKETRAINS(behaviorData,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  behaviorData   :     Table from CPL_READBEHAVIOR. First N-2 variables
%                       are different alignment trials relating to a single
%                       trial per row. Second to last variable is the trial
%                       outcome (0: fail, 1: successful) and last is some
%                       other trial identifier char; for example, 
%                       'L' vs 'R' to delineate between left and right
%                       reaches but could be other things as well.
%
% varargin        :     (OPTIONAL) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Makes figures with rasters aligned to the time points in behaviorData,
%  by Unit, with different subplot columns corresponding to different trial
%  type identifiers from the last column of behaviorData.
%
% By: Max Murphy  v1.0  05/07/2018  Original version (R2017b)
%                                   [rough - could be improved a lot]


%% DEFAULTS
DIR = nan;

DEF_DIR = 'P:\Rat\BilateralReach\Murphy';
SPIKE_DIR = '_wav-sneo_CAR_Spikes';
SPIKE_ID = 'ptrain';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET DIRECTORY
if isnan(DIR)
   DIR = uigetdir(DEF_DIR,'Select recording BLOCK');
   if DIR == 0
      error('No recording BLOCK specified. Script aborted.');
   end
end

block = strsplit(DIR,filesep);
block = block{end};

% %% CONSTRUCT UI - INSTEAD OF DOCKING
% fig = figure('Name','Spike Train Raster Viewer',...
%        'Units','Normalized',...
%        'NumberTitle','off',...
%        'ToolBar','none',...
%        'MenuBar','off');
    
%% LOAD SPIKE TRAINS
F = dir(fullfile(DIR,[block SPIKE_DIR],['*' SPIKE_ID '*.mat']));

X = cell(numel(F),1);
for ii = 1:numel(F)
   in = load(fullfile(F(ii).folder,F(ii).name));
   X{ii} = in.peak_train;
end

%% GET ALIGNMENTS (COULD BE GENERALIZED TO ARBITRARY VARIABLE NAMES, COUNT)
byUnit = CPL_alignspikes(X,behaviorData.Reach);
byUnitG = CPL_alignspikes(X,behaviorData.Grasp);

%% GET INDEXING FOR BEHAVIOR TYPES
iLeft = ismember(behaviorData.Forelimb,'L');
iRight = ismember(behaviorData.Forelimb,'R');

%% PLOT IN DOCKED FIGURES
for ii = 1:numel(F)
   figure('Name',[block ': Channel ' num2str(ii-1,'%02g')],...
          'Color','w',...
          'WindowStyle','docked');
       
   subplot(2,2,1);
   CPL_plotRaster(byUnit{ii}(iLeft),'PlotType','vertline');
   title('Reach - L');
   
   subplot(2,2,2);
   CPL_plotRaster(byUnit{ii}(iRight),'PlotType','vertline');
   title('Reach - R');
   
   subplot(2,2,3);
   CPL_plotRaster(byUnitG{ii}(iLeft),'PlotType','vertline');
   title('Grasp - L');
   
   subplot(2,2,4);
   CPL_plotRaster(byUnitG{ii}(iRight),'PlotType','vertline');
   title('Grasp - R');
   
   suptitle([strrep(block,'_','-') ': Channel ' num2str(ii-1,'%02g')]);
end

end