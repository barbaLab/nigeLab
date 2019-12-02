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
%  channel_struct_ =
%        nigeLab.utils.INITCHANNELSTRUCT(FieldType,channelStruct);
%  --> Matches fields present in channelStruct to identical named fields of
%      the initialized struct for (FieldType). For example, if a struct is
%      initialized as 'Channels', but then you want to switch it to
%      'Streams' (such as in the ReadRHS or ReadRHDHeader functions) then
%      this will match the corresponding 'Streams' fields and discard the
%      rest.
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

if isnumeric(n)
   N = n;
else
   N = 1;
end

%%
switch lower(FieldType)
   case 'channels'
      channel_struct_ = struct( ...
         'name', cell(1,N),...
         'native_channel_name', cell(1,N), ...
         'custom_channel_name', cell(1,N), ...
         'native_order', cell(1,N), ...
         'custom_order', cell(1,N), ...
         'board_stream', cell(1,N), ...
         'chip_channel', cell(1,N), ...
         'port_name', cell(1,N), ...
         'port_prefix', cell(1,N), ...
         'port_number', cell(1,N), ...
         'probe', cell(1,N), ...
         'electrode_impedance_magnitude', cell(1,N), ...
         'electrode_impedance_phase', cell(1,N), ...
         'ml',cell(1,N),...
         'icms',cell(1,N),...
         'area',cell(1,N),...
         'signal', cell(1,N),...
         'chNum',cell(1,N),...
         'chStr',cell(1,N),...
         'fs',cell(1,N));
   case 'streams'
      channel_struct_ = struct( ...
         'name', cell(1,N),...
         'native_channel_name', cell(1,N), ...
         'custom_channel_name', cell(1,N), ...
         'port_name', cell(1,N), ...
         'port_prefix', cell(1,N), ...
         'signal', cell(1,N),...
         'data', cell(1,N),...
         'fs', cell(1,N));      
   case 'events'
      channel_struct_ = struct(...
         'name',cell(1,N),...
         'data',cell(1,N),...
         'status',cell(1,N)...
         )';
      
   case 'videos'
      %
      
   case 'meta'
      %
      
   otherwise
      error('Invalid FieldType: %s\n',FieldType);
      
end


if isstruct(n) % n := struct_in
   channel_struct_ = matchFieldNames(channel_struct_,n);
end

%% Parse additional input
if nargin < 4 % Needs at least 2 varargin for 'name', value pair
   return;
end

for iV = 1:2:numel(varargin)
   name = varargin{iV};
   val = varargin{iV+1};
   if isscalar(val) % Do this part in case val is unique by channel
      val = repmat(val,1,N);
   end
   for iCh = 1:N
      if iscell(val)
         channel_struct_(iCh).(name) = val{iCh};
      else
         channel_struct_(iCh).(name) = val(iCh);
      end
   end
end

   function channel_struct_ = matchFieldNames(channel_struct_,struct_in)
      % MATCHFIELDNAMES  Matches field names of channel_struct_ in
      %                  struct_in, and assigns field values from struct_in
      %                  to the corresponding field of channel_struct_
      
      fn = fieldnames(struct_in);
      for i = 1:numel(fn)
         if ismember(fn{i},fieldnames(channel_struct_))
            channel_struct_.(fn{i}) = struct_in.(fn{i});
         end
      end
   end

end