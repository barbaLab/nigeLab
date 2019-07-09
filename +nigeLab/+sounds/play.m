function play(soundName,speedFactor)
%% PLAY  Play the sound corresponding to [soundName '.mat']
%
%  nigeLab.sounds.play(); % default is 'alert' sound
%  nigeLab.sounds.play('alert');
%  nigeLab.sounds.play('other_sound_file_in_this_folder');
%  nigeLab.sounds.play('alert',2); % play alert sound twice as fast
%
%  Sound file must contain 'sfx' variable which is the 1xnSamples audio 
%  (double) waveform, as well as 'fs' variable, which is the (double
%  scalar) sampling frequency.
%
% By: Max Murphy  v1.0  2019-07-09   Original version (R2017a)

if nargin < 1
   soundName = 'alert';
end

if nargin < 2
   speedFactor = 1;
end

% Parse path to sound file
[~,fname,~] = fileparts(soundName);
p = mfilename('fullpath');
pname = fileparts(p);
soundName = fullfile(pname,[fname '.mat']);

if ~exist(soundName,'file')
   error('No corresponding sound file (%s) in nigeLab/+sounds.',soundName);
end

in = load(soundName,'sfx','fs');
soundsc(in.sfx,in.fs * speedFactor);

end