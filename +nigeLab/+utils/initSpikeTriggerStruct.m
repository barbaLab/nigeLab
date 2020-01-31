function spike_trigger_struct_ = initSpikeTriggerStruct(RecType,n,varargin)
%INITSPIKETRIGGERSTRUCT  Initialize "spike trigger" struct
%
%  spike_trigger_struct_ = initSpikeTriggerStruct;
%  --> scalar spike_trigger_struct 
%
%  spike_trigger_struct_ = initSpikeTriggerStruct(n);
%  --> [1 x n] array of spike_trigger_struct 
%
%  spike_trigger_struct_ = initSpikeTriggerStruct(RecType,n);
%  --> [1 x n] array of spike_trigger_struct (specific) for RecType
%
%  spike_trigger_struct_ = initSpikeTriggerStruct(__,'name',value,...);
%  --> Set 'name' value pairs of struct array equal to something
%      Note: 'name' is case-sensitive and by default is lower-case with '_'
%             where ' ' might normally go.
if nargin < 1
   n = 1;
   RecType = 'Default';
end

switch RecType
   case {'Default','Intan','RHD','RHS'}
      spike_trigger_struct_ = struct( ...
         'voltage_trigger_mode', cell(1,n), ...
         'voltage_threshold', cell(1,n), ...
         'digital_trigger_channel', cell(1,n), ...
         'digital_edge_polarity', cell(1,n),...
         'signal',cell(1,n) ...
         );
   case 'FSM' % Buccelli & Murphy 2019 JNE FSM detector (modified RHS)
      spike_trigger_struct_ = struct( ...
         'fsm_enable', cell(1,n), ...
         'voltage_threshold', cell(1,n), ...
         'amp_trigger_channel', cell(1,n), ...
         'trigger_window_type', cell(1,n), ...   
         'window_start_sample', cell(1,n), ...
         'window_stop_sample', cell(1,n),...
         'signal',cell(1,n) ...
         );
   case 'TDT'
      spike_trigger_struct_ = struct(...
         'signal',cell(1,n) ...
         );
%       spike_trigger_struct_ = struct( ...
         ... 'field1', cell(1,n), ... % Field depends on values to parse
         ... 'field2', cell(1,n) );
   otherwise
      error('Unrecognized RecType: %s',RecType);
end


% Parse additional input
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
         spike_trigger_struct_(iCh).(name) = val{iCh};
      else
         spike_trigger_struct_(iCh).(name) = val(iCh);
      end
   end
end

end