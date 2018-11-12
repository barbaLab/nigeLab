function [class_out,ae,encodings] = DoAutoEncoderClustering(spikes,features,clu,class_in,pw,pp,ae,pars)
%% DOAUTOENCODERCLUSTERING  Use a pre-trained autoencoder to assign cluster
%
%  class_out = DOAUTOENCODERCLUSTERING(spikes,features,clu,class_in,pw,pp);
%  class_out = DOAUTOENCODERCLUSTERING(__,ae,pars);
%  [class_out,ae] = DOAUTOENCODERCLUSTERING(__);
%
%  --------
%   INPUTS
%  --------
%   spikes     :     Array of spikes; columns are samples rows are spikes.
%
%  features    :     N x K array of features, where N is the number of
%                          observations (spikes), and K is the number of
%                          features per observation (for example, number of
%                          wavelet coefficients)
%
%     clu      :     Cluster assignments from  Gaussian Mixture Fit.
%
%   class_in   :     Classes assigned by SPC.
%
%     pw       :     Absolute value of negative-going peak. (pk)
%
%     pp       :     Difference (in samples) of time between this and next
%                    spike. (dt)
%
%     ae       :     (Optional) autoencoder object, to skip training.
%
%    pars      :     (Optional) struct containing clustering parameters. If
%                               not specified, uses default parameters.
%
%  --------
%   OUTPUT
%  --------
%  class_out   :     Cluster class assigned to each spike. Used as a
%                    default cluster assignment to assist in manual
%                    curation using CRC.
%
%     ae       :     Trained stacked autoencoder object.
%
%  encodings   :     Encodings from second autoencoder.
%
% By: Max Murphy  v1.0  01/08/2018  Original version (R2017a)

%% DEFAULTS
if exist('pars','var')==0
   pars = struct;
   % Relevant parameter properties:
   pars.AE_N_HIDDEN_LAYER_1 = 30;
   pars.AE_N_HIDDEN_LAYER_2 = 10;    
   pars.AE_L2_WEIGHT_REG = 0.1;
   pars.AE_SPARSITY_REG  = 2;
   pars.AE_SPARSITY_PROP = 0.01;
   pars.AE_DEC_TRANSFER1  = 'purelin';
   pars.AE_DEC_TRANSFER2 = 'purelin';
   pars.AE_ENC_TRANSFER1 = 'logsig';
   pars.AE_ENC_TRANSFER2 = 'logsig';
   pars.AE_SCALE = true;
   pars.AE_SHOW_PROGRESS = false; 
   pars.AE_AUTOENC1_EPOCHS = 10000;
   pars.AE_AUTOENC2_EPOCHS = 10000;
   pars.AE_READOUT_EPOCHS = 1000;
   pars.AE_NET_EPOCHS = 1000;
end

%% GET FULL FEATURES ARRAY
dt = (log(pp)-mean(log(pp)))./std(log(pp));
pk = (pw-mean(pw))./std(pw);
spk = (spikes./max(max(abs(spikes))))*10;
clus = (clu-mean(clu,2))./std(clu,1);

Z = [spk,features,clus,dt.',pk.'].';
% Z = [features,clus,dt.',pk.'].';

%% TRAIN AUTOENCODER IF NOT SUPPLIED
if exist('ae','var')==0
   % Train first layer
   tic;
   fprintf(1,'Training layer 1...');
   autoenc1 = trainAutoencoder(Z,pars.AE_N_HIDDEN_LAYER_1,...
       'L2WeightRegularization',pars.AE_L2_WEIGHT_REG,...
       'SparsityRegularization',pars.AE_SPARSITY_REG,...
       'SparsityProportion',pars.AE_SPARSITY_PROP,...
       'DecoderTransferFunction',pars.AE_DEC_TRANSFER1,...
       'EncoderTransferFunction',pars.AE_ENC_TRANSFER1,...
       'ShowProgressWindow',pars.AE_SHOW_PROGRESS,...
       'ScaleData',pars.AE_SCALE,...
       'MaxEpochs',pars.AE_AUTOENC1_EPOCHS);
   fprintf(1,'complete.\n');
   toc;
   % Encode first layer
   ft = encode(autoenc1,Z);

   % Train a second autoencoder layer to "stack" for deep learning
   fprintf(1,'Training layer 2...');
   autoenc2 = trainAutoencoder(ft,pars.AE_N_HIDDEN_LAYER_2,...
       'L2WeightRegularization',pars.AE_L2_WEIGHT_REG,...
       'SparsityRegularization',pars.AE_SPARSITY_REG,...
       'SparsityProportion',pars.AE_SPARSITY_PROP,...
       'DecoderTransferFunction',pars.AE_DEC_TRANSFER2,...
       'EncoderTransferFunction',pars.AE_ENC_TRANSFER2,...
       'ShowProgressWindow',pars.AE_SHOW_PROGRESS,...
       'ScaleData',pars.AE_SCALE,...
       'MaxEpochs',pars.AE_AUTOENC2_EPOCHS);
   fprintf(1,'complete.\n');
   toc;
   % Encode features from first layer using second layer
   encodings = encode(autoenc2,ft);
   
   % Convert "class_in" to "targets" format (dummy variable)
   targets = zeros(numel(class_in),max(class_in));
   targets(sub2ind(size(targets),1:size(targets,1),class_in.')) = 1;
   targets = targets.';
   
   % Train softmax read-out layer
   fprintf(1,'Training read-out layer...');
   readout = trainSoftmaxLayer(encodings,targets,...
      'MaxEpochs',pars.AE_READOUT_EPOCHS,...
      'ShowProgressWindow',pars.AE_SHOW_PROGRESS);
   fprintf(1,'complete.\n');
   toc;
   
   % Train stacked network
   fprintf(1,'Training stacked network...');
   ae = stack(autoenc1,autoenc2,readout);
   ae.trainParam.showWindow = pars.AE_SHOW_PROGRESS;
   ae.trainParam.epochs = pars.AE_NET_EPOCHS;
   ae = train(ae,Z,targets);
   fprintf(1,'complete.\n');
   toc;
end

predictions = ae(Z);
[~,class] = max(predictions,[],1);

n = zeros(max(class),1);
for ii = 0:(numel(n)-1)
   n(ii+1) = sum(class==ii);
end
[~,sort_ind] = sort(n,'descend');

class_out = nan(size(class));
for ii = 1:numel(sort_ind)
   class_out(class==sort_ind(ii)) = ii;
end


end



