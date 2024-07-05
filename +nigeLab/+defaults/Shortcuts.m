function varargout = Shortcuts(varargin)
% nigeLab.defaults.SHORTCUTS  Short-hand for indexing workflow stuff
%
%	pars = nigeLab.defaults.SHORTCUTS();

if nargin < 1
   varargin{1} = 'struct';
end
if strcmpi(varargin{1},'cell')
    varargin(1)=[];
   pars = {                                                    % Index
         'raw',         'Channels(%d).Raw.data';                 % 1
         'filt',        'Channels(%d).Filt.data';                % 2
         'car',         'Channels(%d).CAR.data';                 % 3
         'lfp',         'Channels(%d).LFP.data';                 % 4
         'spk',         'Channels(%d).Spikes';                   % 5
         'srt',         'Channels(%d).Sorted';                   % 6
         'clst',        'Channels(%d).Clusters';                 % 7
         'digio',       'Streams.DigIO(%d).data';                % 8
         'anio',        'Streams.AnalogIO(%d).data';             % 9
         'time',        'Meta.Time.data';                        % 10
         'stim',        'Meta.Stim';                             % 11
                                                    };
elseif strcmpi(varargin{1},'struct')
    varargin(1)=[];
   pars = struct;
   pars.raw.subfields = {'Channels', 'Raw'};
   pars.raw.indexable = [true      , true];
   
   pars.filt.subfields = {'Channels', 'Filt'};
   pars.filt.indexable = [true      , true];
   
   pars.car.subfields = {'Channels', 'CAR'};
   pars.car.indexable = [true     , true];
   
   pars.lfp.subfields = {'Channels', 'LFP'};
   pars.lfp.indexable = [true     , true];
   
   pars.spk.subfields = {'Channels', 'Spikes'};
   pars.spk.indexable = [true      , true];
   
   pars.srt.subfields = {'Channels', 'Sorted'};
   pars.srt.indexable = [true      , true];
   
   pars.clst.subfields = {'Channels', 'Clusters'};
   pars.clst.indexable = [true      , true];

   pars.digIO.subfields = {'Streams', 'DigIO', 'data'};
   pars.digIO.indexable = [false    , true   , true];

   pars.anIO.subfields = {'Streams', 'AnalogIO', 'data'};
   pars.anIO.indexable = [false    , true   , true];

   pars.time.subfields = {'Meta', 'Time'};
   pars.time.indexable = [false  , true];

   pars.stim.subfields = {'Meta', 'Stim'};
   pars.stim.indexable = [false  , true];

   pars.n = 1;
else
    pars = nigeLab.defaults.Shortcuts('struct');
end

%% Parse output
nargin_ = length(varargin);
if nargin_ < 1
   varargout = {pars};
else
   varargout = cell(1,nargin_);
   f = fieldnames(pars);
   for i = 1:nargin_
      idx = ismember(lower(f),lower(varargin{i}));
      if sum(idx) == 1
         varargout{i} = pars.(f{idx});
      end
   end
end

end

