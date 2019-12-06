function Shrt = Shortcuts()
% nigeLab.defaults.SHORTCUTS  Short-hand for indexing workflow stuff
%
%	Shrt = nigeLab.defaults.SHORTCUTS();

Shrt = {                                                    % Index
         'raw',         'Channels(%d).Raw.data';                 % 1
         'filt',        'Channels(%d).Filt.data';                % 2
         'car',         'Channels(%d).CAR.data';                 % 3
         'lfp',         'Channels(%d).LFP.data';                 % 4
         'spk',         'Channels(%d).Spikes';                   % 5
         'srt',         'Channels(%d).Sorted';                   % 6
         'clst',        'Channels(%d).Clusters';                 % 7
                                                    };
end

