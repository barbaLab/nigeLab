function flag = doUnitFilter(blockObj)
%% DOUNITFILTER   Filter raw data using spike bandpass filter
%
%  blockObj = nigeLab.Block;
%  doUnitFilter(blockObj);
%
%  Note: added varargin so you can pass <'NAME', value> input argument
%        pairs to specify adhoc filter parameters if desired, rather than
%        modifying the defaults.Filt source code.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% GET DEFAULT PARAMETERS
flag = false;
if ~genPaths(blockObj)
   warning('Something went wrong when generating paths for extraction.');
   return;
end

if ~blockObj.updateParams('Filt')
   warning('Could not update filter parameters.');
   return;
else
   pars = blockObj.FiltPars;
end

fType = blockObj.FileType{strcmpi(blockObj.Fields,'Filt')};

%% DESIGN FILTER
[b,a,zi,nfact,L] = pars.getFilterCoeff(blockObj.SampleRate);

%% DO FILTERING AND SAVE
fprintf(1,'\nApplying bandpass filtering... ');
fprintf(1,'%.3d%%',0)
ProgressPath = fullfile(tempdir,['doUnitFilter',blockObj.Name]);
fid = fopen(ProgressPath,'wb');
fwrite(fid,numel(blockObj.Mask),'int32');
fclose(fid);
updateFlag = false(1,blockObj.NumChannels);
for iCh = blockObj.Mask
   if blockObj.Channels(iCh).Raw.length <= nfact      % input data too short
      error(message('signal:filtfilt:InvalidDimensionsDataShortForFiltOrder',num2str(nfact)));
   end
   if ~pars.STIM_SUPPRESS
      % Filter and and save amplifier_data by probe/channel
      pNum  = num2str(blockObj.Channels(iCh).port_number);
      chNum = blockObj.Channels(iCh).custom_channel_name(...
         regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));      
      fName = sprintf(strrep(blockObj.Paths.Filt.file,'\','/'), ...
         pNum, chNum);
      
      % bank of filters. This is necessary when the designed filter is high
      % order SOS. Otherwise L should be one. See the filter difinition
      % params in defualt.Filt
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
   pct = 100 * (iCh / blockObj.NumChannels);
   if ~floor(mod(pct,5)) % only increment counter by 5%
      fprintf(1,'\b\b\b\b%.3d%%',floor(pct))
   end
   fid = fopen(fullfile(ProgressPath),'ab');
   fwrite(fid,1,'uint8');
   fclose(fid);
end
fprintf(1,'\b\b\b\bDone.\n');
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
[Ys, Zs]  = nigeLab.utils.FilterX.FilterX(b, a, X,  Zi);              % "s"teady state
Yf        = nigeLab.utils.FilterX.FilterX(b, a, Xf, Zs, true);              % "f"inal conditions

% Filter signal again in reverse order:
[~, Zf] = nigeLab.utils.FilterX.FilterX(b, a, Yf, IC * Yf(1));  
Y         = nigeLab.utils.FilterX.FilterX(b, a, Ys, Zf, true);
Y = Y';
end