function str = printLinkFieldString(fieldType,field,print_to_window,precursor)
%% PRINTLINKFIELDSTRING  Standardized Command Window print command for link
%
%  str = nigeLab.utils.PRINTLINKFIELDSTRING(fieldType,field);
%
%  fieldType: {'Channels', 'Streams', 'Events', 'Videos', or 'Meta'}
%  field: Member of blockObj.Fields;
%
%  str: If used in fprintf, reproduces the printed statement without
%  leading and trailing '\n' and trailing percentage.

%%
if nargin < 3
   print_to_window = false;
end

if nargin < 4
   precursor = 'Linking';
end

linkStr = '<a href="matlab:doc nigelab.Block/%s">%s</a>';
fieldTypeStr = sprintf(linkStr,fieldType,fieldType);
switch lower(field)
   case {'raw','rawdata','filt','filtdata','car','referenced'}
      fieldStr = sprintf(linkStr,'doRawExtraction',field);
   case {'artifact','spikes','features','spikefeatures'}
      fieldStr = sprintf(linkStr,'doSD',field);
   case {'clusters'}
      fieldStr = sprintf(linkStr,'doAutoClustering',field);
   case {'sorted','sort'}
      fieldStr = sprintf('<a href="matlab:doc nigelab.Sort">%s</a>',field);
   case {'lfp','localfieldpotential'}
      fieldStr = sprintf(linkStr,'doLFPExtraction',field);
   case {'digio','analogio'}
      fieldStr = sprintf(linkStr,'doRawExtraction',field);
   case {'digevents','scoredevents'}
      fieldStr = sprintf(linkStr,'scoreVideo',field);
   case {'time'}
      fieldStr = sprintf(linkStr,'doRawExtraction',field);
   case {'video','vidstreams','vid'}
      fieldStr = sprintf('<a href="matlab:doc nigelab.defaults.Video">%s</a>',field);
   otherwise
      fieldStr = field;
end
str = sprintf('%s %s field: %s',precursor,fieldTypeStr,fieldStr);
if print_to_window
   fprintf(1,['\n' str '...000%%\n']);
end
end