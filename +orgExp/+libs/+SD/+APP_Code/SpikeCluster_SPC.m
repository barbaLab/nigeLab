function SPC_out = SpikeCluster_SPC(features,iCh,pars)
%% SPIKECLUSTER_SPC Cluster spikes using super-paramagnetic clustering (SPC). More accurate than K-means or Bayes methods, but potentially takes longer.
%
% SPC_out = SPIKECLUSTER_SPC(features,iCh,pars)
%
%   --------
%    INPUTS
%   --------
%   features    :   Features to use for clustering.
%
%    iCh        :   Channel index.
%
%    pars       :   Parameters structure.
%
%   --------
%    OUTPUT
%   --------
%    SPC_out    :   Cell with computed clusters from using SPC.
%
% Adapted from Quian Quiroga et. al 2004
% By: Max Murphy    v3.0    08/11/2017  Major changes in order to make it
%                                       flow better with adapted
%                                       functionality from recent overall
%                                       changes to spike detection. Removed
%                                       useless "handles" that was
%                                       redundant with "pars" struct.
%                   v2.3    02/03/2017  Added ability to change the mother
%                                       wavelet family.
%                   v2.2    02/02/2017  Slightly modified some command
%                                       window outputs to add clarity in
%                                       the case of no spikes detected or
%                                       low cluster counts, etc.
%                   v2.1    01/30/2017  Fixed minor bug with pars. Added
%                                       iCh input to allow parfor to create
%                                       unique filenames when running on
%                                       local machine.
%                   v2.0    01/29/2017  Changed parameter handling.

%% CHECK THAT THERE ARE ENOUGH SPIKES TO RUN CLUSTER.EXE
SPC_out = struct;
ch = num2str(iCh);
pars.nspikes = size(features,1);
if pars.nspikes < pars.MIN_SPK  % Meets criteria for min number of spikes
    SPC_out.class = zeros(pars.nspikes,1);
    SPC_out.clu = nan;
    SPC_out.tree = nan;
    SPC_out.temperature = nan;
    SPC_out.pars = pars;
    return;
end              

%% DO CLUSTERING
spc_pars = init_SPC_parameters(ch);
[class,clu,tree,pars.temperature] = DoSPC(features,spc_pars);
class = ReduceClusters(features,class);

%% SAVE INDIVIDUAL "CLUSTER" FILES
SPC_out = struct;
SPC_out.class = class;
SPC_out.clu = clu;
SPC_out.tree = tree;
SPC_out.pars = pars;

   function spc_pars = init_SPC_parameters(ch)
      spc_pars = struct;
      spc_pars.SPC_VERBOSE = true;
      spc_pars.SPC_TEMPLATE = 'center';
      spc_pars.SPC_DISCARD_EXTRA_CLUS = false;         % If true, don't do template match
      spc_pars.SPC_FNAME_IN = ['tmp_data' ch];              % Input name for cluster.exe
      spc_pars.SPC_FNAME_OUT = ['data_tmp_curr' ch '.mat']; % Read-out from cluster.exe
      spc_pars.SPC_RANDOMSEED = 147;                   % Random seed
      spc_pars.SPC_RANDOMIZE = false;                  % Use random subset for SPC?
      spc_pars.SPC_ABS_KNN = 10;                       % Absolute (min) K-Nearest Neighbors
      spc_pars.SPC_REL_KNN = 0.0001;                   % Relative K-Nearest Neighbors
      spc_pars.SPC_SWCYC = 100;                   % Swendsen-Wang cycles
      spc_pars.SPC_TSTEP = 0.001;                 % Increments for vector of temperatures
      spc_pars.SPC_MAXTEMP = 0.300;               % Max. temperature for SPC
      spc_pars.SPC_MINTEMP = 0.000;               % Min. temperature for SPC
      spc_pars.SPC_NMINCLUS = 7;                  % Absolute minimum cluster size diff
      spc_pars.SPC_RMINCLUS = 0.006;              % Relative minimum cluster size diff
      spc_pars.SPC_MAX_SPK = 1000;                % Max. # of spikes per SPC batch
      spc_pars.SPC_TEMPLATE_PROP = 0.25;          % Proportion for SPC before starting template match
      spc_pars.SPC_TEMPSD = 1.50;                 % # of SD for template matching
      spc_pars.SPC_NCLUS_MIN = 25;                % For use with 'neo' option
      spc_pars.SPC_NCLUS_MAX = 1000;              % Max. # of clusters
      spc_pars.SPC_TEMP_METHOD = 'neo';           % Method of finding temperature
                                  % ('iterate', 'max', 'cost', 'nclus', or 'neo')
   end

end