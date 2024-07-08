function flag = initChannels(blockObj,header)
%INITCHANNELS   Initialize header information for channels
%
%  flag = blockObj.initChannels;
%  flag = blockObj.initChannels(header);
%  --> Uses custom-defined 'header' struct

%GET HEADER INFO DEPENDING ON RECORDING TYPE
flag = false;
if nargin < 2
   [header,fid] = parseHeader(blockObj);
   if ~isempty(fid)
      fclose(fid); % Make sure that file is closed after parsing header
   end
end

%ASSIGN DATA FIELDS USING HEADER INFO
blockObj.Channels = header.RawChannels;
blockObj.RecSystem = nigeLab.utils.AcqSystem(header.Acqsys);

if ~blockObj.parseProbeNumbers % Depends on recording system
   if blockObj.Verbose
      [fmt,idt] = getDescriptiveFormatting(blockObj);
      nigeLab.utils.cprintf(fmt,'%s[BLOCK/INITSTREAMS]: ',idt);
      nigeLab.utils.cprintf(fmt(1:(end-1)),'(%s)',blockObj.Name); 
      nigeLab.utils.cprintf('[0.55 0.55 0.55]','No PROBES initialized\n');
   end
   return;
end
blockObj.SampleRate = header.SampleRate;
blockObj.Samples = header.NumRawSamples;

%SET CHANNEL MASK (OR IF ALREADY SPECIFIED MAKE SURE IT IS CORRECT)
if isfield(header,'Mask')
   blockObj.Mask = reshape(find(header.Mask),1,numel(header.Mask));
elseif isempty(blockObj.Mask)
   blockObj.Mask = 1:blockObj.NumChannels;
elseif islogical(blockObj.Mask)
   if numel(blockObj.Mask)~=numel(blockObj.NumChannels)
      error(['nigeLab:' mfilename ':MaskChannelsMismatch'],...
         ['[BLOCK/INITCHANNELS]: %s.Mask is a logical vector ' ...
         'but has %g elements while there are %g Channels\n'],...
          blockObj.Name,numel(blockObj.Mask),blockObj.NumChannels);
   end
   % Convert to `double`
   blockObj.Mask = find(blockObj.Mask); 
elseif isnumeric(blockObj.Mask)
   blockObj.Mask(blockObj.Mask > blockObj.NumChannels) = [];
   blockObj.Mask(blockObj.Mask < 1) = [];
   blockObj.Mask = reshape(blockObj.Mask,1,numel(blockObj.Mask));
else
   error(['nigeLab:' mfilename ':InvalidMaskType'],...
      '%s.Mask is assigned an invalid class of value (%s)\n',...
         blockObj.Name,class(blockObj.Mask));
end

flag = true;

end