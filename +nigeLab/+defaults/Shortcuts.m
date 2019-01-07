function Shrt = Shortcuts()
%% nigeLab.defaults.SHORTCUTS  Short-hand for indexing workflow stuff
%
%	Shrt = nigeLab.defaults.SHORTCUTS();
%
% By: MAECI 2018 collaboration (Max Murphy & Federico Barban)

Shrt = {                                                    % Index
         'raw',         'Channels(%d).Raw';                 % 1
         'filt',        'Channels(%d).Filt';                % 2
         'car',         'Channels(%d).CAR';                 % 3
         'lfp',         'Channels(%d).LFP';                 % 4
         'spk',         'Channels(%d).Spikes';              % 5
         'srt',         'Channels(%d).Sorted';              % 6
         'clst',        'Channels(%d).Clusters';            % 7
         'dig',         'DigInChannels(%d).data';
                                                    };
end

