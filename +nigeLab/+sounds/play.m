function out = play(soundName,speedFactor,dbAttenuation)
%PLAY  Play the sound corresponding to [soundName '.mat']
%
%  nigeLab.sounds.play(); % default is 'alert' sound
%  >> Plays 'alert' by default
%
%  nigeLab.sounds.play('pop');
%  >> Play 'pop' sound
%    * Other values are 'camera', 'bell', 'alert'
%
%  nigeLab.sounds.play('other_sound_file_in_this_folder');
%  >> Play a different file
%    * Sound file must contain 'sfx' variable which is the 1xnSamples audio 
%      (double) waveform, as well as 'fs' variable, which is the (double
%       scalar) sampling frequency.
%    * 'sfx' field should be scaled between zero and one with zero-mean
%
%  nigeLab.sounds.play('alert',2); 
%  >> play alert sound twice as fast
%    * Default `fs` is specified in `.mat` file of the sound to be played
%
%  nigeLab.sounds.play('alert',1,-50);  
%  >> Play 'alert' tone at nomral frequency with 50 dB attenuation
%    * Standard attenuation is -30 dB


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

if nargin < 3
   dbAttenuation = -30;
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
   out = in.sfx - median(in.sfx);
   out = in.sfx./max(abs(in.sfx)).*db2mag(dbAttenuation);
   sound(out,min(in.fs * speedFactor,192000));
catch
   % do nothing
end

end