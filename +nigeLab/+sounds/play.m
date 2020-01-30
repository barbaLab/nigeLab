function play(soundName,speedFactor)
%PLAY  Play the sound corresponding to [soundName '.mat']
%
%  nigeLab.sounds.play(); % default is 'alert' sound
%  nigeLab.sounds.play('alert');
%  nigeLab.sounds.play('other_sound_file_in_this_folder');
%  nigeLab.sounds.play('alert',2); % play alert sound twice as fast
%
%  Sound file must contain 'sfx' variable which is the 1xnSamples audio 
%  (double) waveform, as well as 'fs' variable, which is the (double
%  scalar) sampling frequency.

p = mfilename('fullpath');
pname = fileparts(p);

if nargin < 1
   soundName = 'alert';
elseif ismember(lower(soundName),{'help','options','opts','sounds'})
   F = dir(fullfile(pname,'*.mat'));
   soundList = {F.name};
   soundList = cellfun(@(c)c(1:(end-4)),soundList,'UniformOutput',false);
   disp(soundList);
   return;
end

if nargin < 2
   speedFactor = 1;
end

% Parse path to sound file (must be in ~/+nigeLab/+sounds/ folder)
[~,fname,~] = fileparts(soundName);
soundName = fullfile(pname,[fname '.mat']);

if ~exist(soundName,'file')
   warning('No corresponding sound file (%s) in nigeLab/+sounds.',soundName);
   return;
end

try
   in = load(soundName,'sfx','fs');
   soundsc(in.sfx,in.fs * speedFactor);
catch
   % do nothing
end

end