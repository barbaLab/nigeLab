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
                                                    };
else
   pars = struct;
   pars.raw = 'Channels(%d).Raw.data';
   pars.filt = 'Channels(%d).Filt.data';
   pars.car = 'Channels(%d).CAR.data';
   pars.lfp = 'Channels(%d).LFP.data';
   pars.spk = 'Channels(%d).Spikes';
   pars.srt = 'Channels(%d).Sorted';
   pars.clst = 'Channels(%d).Clusters';
end

end

