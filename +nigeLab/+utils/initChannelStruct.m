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
   case {'ch','chan','channel','channels'}
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
      
   case {'strm','stream','streams'}
      channel_struct_ = struct( ...
         'name', cell(1,N),...
         'native_channel_name', cell(1,N), ...
         'custom_channel_name', cell(1,N), ...
         'port_name', cell(1,N), ...
         'port_prefix', cell(1,N), ...
         'signal', cell(1,N),...
         'data', cell(1,N),...
         'fs', cell(1,N));    
      
   case {'evt','event','events'}
      channel_struct_ = struct(...
         'name',cell(1,N),...
         'data',cell(1,N),...
         'status',cell(1,N)...
         )';
      
   case {'sub','substreams','substream'}
      channel_struct_ = struct( ...
         'name', cell(1,N),...
         'data', cell(1,N),...
         't', cell(1,N),...
         'fs', cell(1,N));    
   
   case {'vidstream','vidstreams'}
      channel_struct_ = struct('info',cell(1,N),...
            'diskdata',cell(1,N),...
            'tag',cell(1,N),...
            't',cell(1,N),...
            'fs',cell(1,N));
      
   case {'vid','video','videos'}
      channel_struct_ = struct;
      return;
      
   case {'meta','metadata'}
      channel_struct_ = struct;
      return;
      
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
      fn_reduced = fieldnames(channel_struct_);
      tmp = nigeLab.utils.fixNamingConvention(struct_in);
      fn_ = fieldnames(tmp);
      fn_reduced_ = nigeLab.utils.fixNamingConvention(fieldnames(channel_struct_));
      
      for i = 1:numel(fn)
         if isempty(struct_in)
            data_assign = [];
         else
            data_assign = struct_in.(fn{i});
         end
         
         if ismember(fn{i},fn_reduced) % If it's a member, assign it
            channel_struct_.(fn{i}) = data_assign;
            
         else % If not, check for match agnostic to capitalization
            i_match = find(ismember(lower(fn_reduced),lower(fn{i})),1,'first');
            if numel(i_match) == 1
               channel_struct_.(fn_reduced{i_match}) = data_assign;
               
            else % If still no, fix naming convention and check for match
               i_match = find(ismember(fn_reduced_,fn_{i}),1,'first');
               if numel(i_match) == 1
                  channel_struct_.(fn_reduced{i_match}) = data_assign;
               end % If still no, then it is not a field to match
            end            
         end
      end
   end

end