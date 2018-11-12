function qCluster(varargin)
%% QCLUSTER    Do clustering for spikes that are already detected
%
%  QCLUSTER;
%  QCLUSTER('DIR',[recording block name]);
%  QCLUSTER('NAME1',value1,'NAME2',value2,...);
%
%  --------
%   INPUTS
%  --------
%  varargin    :     (Optional) input argument pairs
%
%
%     -> 'DIR' || nan (def) 
%                 [Specify as path to recording block to bypass
%                  the selection UI, useful for looping batches]
%
%     -> 'SPK' || nan (def) 
%                 [Specify as spikes subfolder of recording block to bypass
%                  the selection UI, useful for looping batches]
%
%     -> 'METHOD' || 'spc' (def), 'temp', 'ae'
%                    [Clustering method]
%
%  --------
%   OUTPUT
%  --------
%  Creates a new folder with automated cluster class assignments.
%
% By: Max Murphy  v1.0  01/05/2018  Original version (R2017a)

%% DEFAULTS
DIR = nan;
SPK = nan;
METHOD = 'spc';   % spc, temp (template matching), ae (autoencoder)

% Meta-parameters
DEF_DIR = 'P:\Rat';
SPK_DIR = 'Spikes';
SPK_ID = 'ptrain';

CLU_DIR = 'Clusters';
CLU_ID = 'clus';


%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET RECORDING DIRECTORY
if isnan(DIR)
   DIR = uigetdir(DEF_DIR,'Select recording BLOCK');
   if DIR == 0
      error('No recording block selected. Script aborted.');
   end   
end

%% GET SPIKES DIRECTORY
block = strsplit(DIR,filesep);
rat = strjoin(block(1:(end-1)),filesep);
block = block{end};
name = block(1:regexp(block,'[_]'));

if isnan(SPK)
   SPK = dir(fullfile(DIR, [block '*' SPK_DIR]));
   SPK(~[SPK.isdir]) = [];

   if numel(SPK)>1
      [~,ind] = uidropdownbox('Multiple Spike Directories Detected',...
         'Select spikes to sort',...
         {SPK.name}.');
      if isnan(ind)
         error('No spike directory selected. Script aborted.');
      else
         SPK = fullfile(DIR,SPK(ind).name);
         fprintf(1,'\nUsing %s to cluster \n->\t%s...\n',METHOD,SPK);
      end
   else
      SPK = fullfile(DIR,SPK.name);
   end
end

sd_data = strsplit(SPK,filesep);
sd_data = sd_data{end};
sd_data = strsplit(sd_data,'_');
if strcmp(sd_data{end-1},'CAR')
   cludir = strjoin([sd_data(1:end-2),{upper(METHOD)},{'CAR'},{CLU_DIR}],'_');
else
   cludir = strjoin([sd_data(1:end-2),{upper(METHOD)},{CLU_DIR}],'_');
end

CLU = fullfile(DIR,cludir);
if exist(CLU,'dir')==0
   mkdir(CLU);
end

%% LOAD EACH SPIKE FILE AND DO FEATURE EXTRACTION
F = dir(fullfile(SPK,['*' SPK_ID '*.mat']));

fprintf(1,'\nClustering...\n');
for iF = 1:numel(F)
   fname = strrep(F(iF).name,SPK_ID,CLU_ID);
   fprintf(1,'->\t%s\n',fname);
   load(fullfile(SPK,F(iF).name),...
      'spikes','features','pw','pp','pars'); % Loads spikes, "features"
   
   % gmfa: Gaussian-Mixture Feature Assignments
   gmfa = DoTemplateClustering(features,pw,pp); 
   gmfa(:,any(isnan(gmfa),1)) = [];
   gmfa = (gmfa-mean(gmfa,1))./max(std(gmfa,[],1),ones(1,size(gmfa,2)));
   gmfa(:,abs(mode(gmfa,1))<=eps) = [];
   
   class = DoSPC(gmfa);
   class = ReduceClusters(spikes,class);
   
   save(fullfile(CLU,fname),'class','pars','-v7.3');   
end


end