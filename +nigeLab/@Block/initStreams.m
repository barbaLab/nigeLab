function flag = initStreams(blockObj,header)
%INITSTREAMS Initialize Streams struct for nigeLab.Block class object
%
%  flag = INITSTREAMS(blockObj);
%
%  flag: Returns false if initialized correctly; otherwise, returns true
%        (so it is really "warningFlag")

flag = false;
if nargin < 2
   [header,fid] = blockObj.parseHeader();
   if ~isempty(fid)
      fclose(fid);
   end
end

[fieldIdx,nStreamTypes] = blockObj.getFieldTypeIndex('Streams');
fields = blockObj.Fields(fieldIdx);
if sum(fieldIdx) == 0
   flag = true;
   if blockObj.Verbose
      [fmt,idt] = getDescriptiveFormatting(blockObj);
      nigeLab.utils.cprintf(fmt,'%s[BLOCK/INITSTREAMS]: ',idt);
      nigeLab.utils.cprintf(fmt(1:(end-1)),'(%s)',blockObj.Name); 
      nigeLab.utils.cprintf('[0.55 0.55 0.55]','No STREAMS initialized\n');
   end
   return;
end

blockObj.Streams = struct;
for ii = 1:nStreamTypes
   name = fields{ii};
   headerFields = fieldnames(header);
   headerStructName = [name 'Channels'];
   if isempty(header.(headerStructName))
      if blockObj.Verbose
         [fmt,idt,type] = getDescriptiveFormatting(blockObj);
         nigeLab.utils.cprintf('Errors*','%s[BLOCK/INITSTREAMS]: ',idt);
         nigeLab.utils.cprintf(fmt,...
            'Empty header for %s\n',name);
         nigeLab.utils.cprintf(fmt(1:(end-1)),...
            ['\t%s(Check that +defaults/%s pars.Fields '...
            'match your experiment)'],idt,type);
      end
      blockObj.Streams.(name) = nigeLab.utils.initChannelStruct('Streams',0);
      continue;
   end
   if ismember(headerStructName,headerFields)
      blockObj.Streams.(name) = nigeLab.utils.initChannelStruct('Streams',...
         header.(headerStructName));
   else
      if blockObj.Verbose
         [fmt,idt] = getDescriptiveFormatting(blockObj);
         nigeLab.utils.cprintf('Errors*','%s[BLOCK/INITSTREAMS]: ',idt);
         nigeLab.utils.cprintf(fmt,'Missing header for %s\n',name);
         nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
            '\t%s(Initializing empty Streams struct: %s)\n',...
            idt,headerStructName);
      end
      blockObj.Streams.(name) = nigeLab.utils.initChannelStruct('Streams',0);
   end
end
flag = true;


end

