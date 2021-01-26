function flag = doUnitFilter(blockObj)
%DOUNITFILTER   Filter raw data using spike bandpass filter
%
%  blockObj = nigeLab.Block;
%  doUnitFilter(blockObj);
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

% IMPORTS
import nigeLab.libs.DiskData;
import nigeLab.utils.getNigeLink;

% GET DEFAULT PARAMETERS
if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      if ~isempty(blockObj(i))
         if isvalid(blockObj(i))
            flag = flag && doUnitFilter(blockObj(i));
         end
      end
   end
   return;
else
   flag = false;
end
blockObj.checkActionIsValid();

if ~genPaths(blockObj)
   warning('Something went wrong with extraction.');
   return;
end

[~,pars] = blockObj.updateParams('Filt');
fType = blockObj.FileType{strcmpi(blockObj.Fields,'Filt')};

% ENSURE MASK IS ACCURATE
blockObj.checkMask;

% DESIGN FILTER
[b,a,zi,nfact,L] = pars.getFilterCoeff(blockObj.SampleRate);

% DO FILTERING AND SAVE
if ~blockObj.OnRemote
   str = getNigeLink('nigeLab.Block','doUnitFilter',...
      'Unit Bandpass Filter');
   str = sprintf('Applying %s',str);
else
   str = 'Filtering';
end

blockObj.reportProgress(str,0,'toWindow','Filtering');

curCh = 0;
nCh = numel(blockObj.Mask);
for iCh = blockObj.Mask   
   curCh = curCh + 1;
   if blockObj.Channels(iCh).Raw.length <= nfact
      continue; % It should leave the updateFlag as false for this channel
   end
   if ~pars.STIM_SUPPRESS
       data = blockObj.Channels(iCh).Raw(:);
   else
       data = blockObj.execStimSuppression(iCh);
   end
      % Filter and and save amplifier_data by probe/channel
      pNum  = num2str(blockObj.Channels(iCh).probe);
      chNum = blockObj.Channels(iCh).chStr;   
      fName = sprintf(strrep(blockObj.Paths.Filt.file,'\','/'), ...
         pNum, chNum);
      
      % bank of filters. This is necessary when the designed filter is high
      % order SOS. Otherwise L should be one. See the filter definition
      % params in default.Filt
      for ii=1:L
         data = (ff(b,a,data,nfact,zi));
      end
      
      blockObj.Channels(iCh).Filt = DiskData(...
         fType,fName,data,...
         'access','w',...
         'size',size(data),...
         'class',class(data),...
         'overwrite',true);
      
      lockData(blockObj.Channels(iCh).Filt);

   
   blockObj.updateStatus('Filt',true,iCh);
   pct = round(curCh/nCh * 90);
   blockObj.reportProgress(str,pct,'toWindow','Filtering');
   blockObj.reportProgress('Filtering.',pct,'toEvent');
end

if blockObj.OnRemote
   str = 'Saving-Block';
   blockObj.reportProgress(str,95,'toWindow',str);
else
   blockObj.save;
   linkStr = blockObj.getLink('Filt');
   str = sprintf('<strong>Unit Filtering</strong> complete: %s\n',linkStr);
   blockObj.reportProgress(str,100,'toWindow','Done');
   blockObj.reportProgress('Done',100,'toEvent');
end

flag = true;

end

function Y = ff(b,a,X,nEdge,IC)


% nedge dimension of the edge effect
% IC initial condition. can usually be computed as
% K       = eye(Order - 1);
% K(:, 1) = a(2:Order);
% K(1)    = K(1) + 1;
% K(Order:Order:numel(K)) = -1.0;
% IC      = K \ (b(2:Order) - a(2:Order) * b(1));
% where order is the filter order as 
% Order = max(nb, na);

import nigeLab.utils.FilterX.*;

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
[~, Zi] = FilterX(b, a, Xi, IC * Xi(end),true);   

% Use the final conditions of the initial part for the actual signal:
[Ys, Zs]  = FilterX(b, a, X,  Zi);                    % "s"teady state
Yf        = FilterX(b, a, Xf, Zs, true);              % "f"inal conditions

% Filter signal again in reverse order:
[~, Zf] = FilterX(b, a, Yf, IC * Yf(1));  
Y         = FilterX(b, a, Ys, Zf, true);
Y = Y';
end