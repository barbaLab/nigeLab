function flag = doUnitFilter(blockObj)
%% DOUNITFILTER   Filter raw data using spike bandpass filter
%
%  blockObj = nigeLab.Block;
%  doUnitFilter(blockObj);
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% GET DEFAULT PARAMETERS
flag = false;
blockObj.checkActionIsValid();
nigeLab.utils.checkForWorker('config');
   
if ~genPaths(blockObj,blockObj.AnimalLoc)
   warning('Something went wrong when generating paths for extraction.');
   return;
end

if ~blockObj.updateParams('Filt')
   warning('Could not update filter parameters.');
   return;
else
   pars = blockObj.Pars.Filt;
end
reportProgress(blockObj,'Filtering',0);
fType = blockObj.FileType{strcmpi(blockObj.Fields,'Filt')};

%% ENSURE MASK IS ACCURATE
blockObj.checkMask;

%% DESIGN FILTER
[b,a,zi,nfact,L] = pars.getFilterCoeff(blockObj.SampleRate);

%% DO FILTERING AND SAVE
reportProgress(blockObj,'Filtering',0);
updateFlag = false(1,blockObj.NumChannels);
for iCh = blockObj.Mask
%    if blockObj.Channels(iCh).Raw.length <= nfact      % input data too short
%       error(message('signal:filtfilt:InvalidDimensionsDataShortForFiltOrder',num2str(nfact)));
%    end
   if blockObj.Channels(iCh).Raw.length <= nfact
      continue; % It should leave the updateFlag as false for this channel
   end
   if ~pars.STIM_SUPPRESS
      % Filter and and save amplifier_data by probe/channel
      pNum  = num2str(blockObj.Channels(iCh).port_number);
      chNum = blockObj.Channels(iCh).custom_channel_name(...
         regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));      
      fName = sprintf(strrep(blockObj.Paths.Filt.file,'\','/'), ...
         pNum, chNum);
      
      % bank of filters. This is necessary when the designed filter is high
      % order SOS. Otherwise L should be one. See the filter definition
      % params in default.Filt
      data = blockObj.Channels(iCh).Raw(:);
      for ii=1:L
         data = (ff(b,a,data,nfact,zi));
      end
      
      blockObj.Channels(iCh).Filt = nigeLab.libs.DiskData(...
         fType,fName,data,...
         'access','w',...
         'size',size(data),...
         'class',class(data));
      
      blockObj.Channels(iCh).Filt = lockData(blockObj.Channels(iCh).Filt);
   else
      warning('STIM SUPPRESSION method not yet available.');
      return;
   end
   
   updateFlag(iCh) = true;
   pct = floor(iCh/max(blockObj.Mask)*100);
   reportProgress(blockObj,'Filtering',pct);
   
end
blockObj.updateStatus('Filt',updateFlag);
flag = true;
blockObj.save;

end

function Y = ff(b,a,X,nEdge,IC)

%%
% nedge dimension of the edge effect
% IC initial condition. can usually be computed as
% K       = eye(Order - 1);
% K(:, 1) = a(2:Order);
% K(1)    = K(1) + 1;
% K(Order:Order:numel(K)) = -1.0;
% IC      = K \ (b(2:Order) - a(2:Order) * b(1));
% where order is the filter order as 
% Order = max(nb, na);

% User Interface: --------------------------------------------------------------
% Do the work: =================================================================
% Create initial conditions to treat offsets at beginning and end:
if ~iscolumn(X),X=X(:);end
% Use a reflection to extrapolate signal at beginning and end to reduce edge
% effects (BSXFUN would be some micro-seconds faster, but it is not available in
% Matlab 6.5):
Xi   = 2 * X(1) - X(2:(nEdge + 1));

Xf   = 2 * X(end) - X((end - nEdge):(end - 1));

% Use the faster C-mex filter function: -------------------------
% Filter initial reflected signal:
[~, Zi] = nigeLab.utils.FilterX.FilterX(b, a, Xi, IC * Xi(end),true);   

% Use the final conditions of the initial part for the actual signal:
[Ys, Zs]  = nigeLab.utils.FilterX.FilterX(b, a, X,  Zi);                    % "s"teady state
Yf        = nigeLab.utils.FilterX.FilterX(b, a, Xf, Zs, true);              % "f"inal conditions

% Filter signal again in reverse order:
[~, Zf] = nigeLab.utils.FilterX.FilterX(b, a, Yf, IC * Yf(1));  
Y         = nigeLab.utils.FilterX.FilterX(b, a, Ys, Zf, true);
Y = Y';
end