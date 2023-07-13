function pars = Shortcuts(out_mode)
% nigeLab.defaults.SHORTCUTS  Short-hand for indexing workflow stuff
%
%	pars = nigeLab.defaults.SHORTCUTS();

if nargin < 1
   out_mode = 'struct';
end
if strcmpi(out_mode,'cell')
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
else
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
end

end

