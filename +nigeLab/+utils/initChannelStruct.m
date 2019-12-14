function channel_struct_ = initChannelStruct(FieldType,n,varargin)
%% INITCHANNELSTRUCT  Initialize STREAMS channel struct with correct fields
%
%  channel_struct_ = nigeLab.utils.INITCHANNELSTRUCT;
%   --> Initialize 'Channels' (FieldType) Channels struct scalar (default)
%
%  channel_struct_ = nigeLab.utils.INITCHANNELSTRUCT(FieldType);
%   --> Initialize 'FieldType' Channels struct scalar
%        * Valid FieldType options (2019-11-21):
%           - 'Channels'
%           - 'Streams'
%
%  channel_struct_ = nigeLab.utils.INITCHANNELSTRUCT(n);
%   --> Initialize as [1 x n] 'Channels' (FieldType) Channels struct array
%
%  channel_struct_ = nigeLab.utils.INITCHANNELSTRUCT(FieldType,n);
%   --> Initialize as [1 x n] 'FieldType' Channels struct array
%
%  channel_struct_ = nigeLab.utils.INITCHANNELSTRUCT(__,'name',value,...);
%   --> Sets struct value of 'name' to corresponding value (for each
%        struct array element
%      Note: 'name' is case-sensitive and by default is lower-case with '_'
%             where ' ' might normally go.

%%
if nargin < 2
   if isnumeric(FieldType)
      n = FieldType;
      FieldType = 'Channels';
   else
      n = 1;
   end
end

if nargin < 1
   FieldType = 'Channels';
end

%%
switch lower(FieldType)
   case 'channels'
      channel_struct_ = struct( ...
         'native_channel_name', cell(1,n), ...
         'custom_channel_name', cell(1,n), ...
         'native_order', cell(1,n), ...
         'custom_order', cell(1,n), ...
         'board_stream', cell(1,n), ...
         'chip_channel', cell(1,n), ...
         'port_name', cell(1,n), ...
         'port_prefix', cell(1,n), ...
         'port_number', cell(1,n), ...
         'probe', cell(1,n), ...
         'electrode_impedance_magnitude', cell(1,n), ...
         'electrode_impedance_phase', cell(1,n), ...
         'signal', cell(1,n),...
         'chNum',cell(1,n),...
         'chStr',cell(1,n));
      
   case 'streams'
      channel_struct_ = struct( ...
         'native_channel_name', cell(1,n), ...
         'custom_channel_name', cell(1,n), ...
         'native_order', cell(1,n), ...
         'custom_order', cell(1,n), ...
         'board_stream', cell(1,n), ...
         'chip_channel', cell(1,n), ...
         'port_name', cell(1,n), ...
         'port_prefix', cell(1,n), ...
         'port_number', cell(1,n), ...
         'electrode_impedance_magnitude', cell(1,n), ...
         'electrode_impedance_phase', cell(1,n), ...
         'signal', cell(1,n),...
         'data', cell(1,n));
      
   case 'events'
      channel_struct_ = struct(...
         'name',cell(1,n),...
         'data',cell(1,n),...
         'status',cell(1,n)...
         )';
      
   case 'videos'
      %
      
   case 'meta'
      %
      
   otherwise
      error('Invalid FieldType: %s\n',FieldType);
      
end

%% Parse additional input
if nargin < 4 % Needs at least 2 varargin for 'name', value pair
   return;
end

for iV = 1:2:numel(varargin)
   name = varargin{iV};
   val = varargin{iV+1};
   if isscalar(val) % Do this part in case val is unique by channel
      val = repmat(val,1,n);
   end
   for iCh = 1:n
      if iscell(val)
         channel_struct_(iCh).(name) = val{iCh};
      else
         channel_struct_(iCh).(name) = val(iCh);
      end
   end
end

end