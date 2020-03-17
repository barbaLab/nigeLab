function flag = doTrialVidExtraction(blockObj,isExtracted)
%DOTRIALVIDEXTRACTION  Extract Trial Videos 
%
%  flag = doTrialVidExtraction(blockObj);

if nargin < 2
   isExtracted = false;
end

if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      flag = flag && doTrialVidExtraction(blockObj(i),isExtracted);
   end
   return;
end

if isempty(blockObj)
   flag = true;
   return;
elseif ~isvalid(blockObj)
   flag = true;
   return;
end

if ~checkActionIsValid(blockObj)
   flag = true;
   return;
end

% Get all the trial "start" times and "stop" times
fprintf(1,'\t\t->\t<strong>[DOTRIALVIDEXTRACTION]</strong>::%s: ',...
   blockObj.Name);
fprintf(1,'Formatting trial epochs...');
[tStart,tStop] = getTrialStartStopTimes(blockObj);

if numel(tStart) ~= numel(tStop)
   error(['nigeLab:' mfilename ':BadTrialStructure'],...
      ['\t\t->\t<strong>[DOTRIALVIDEXTRACTION]</strong>: ' ...
      'Number of tStart (%g) does not equal number of tStop (%g)'],...
      numel(tStart),numel(tStop));
end

if isExtracted && isfield(blockObj.Paths.V,'Orig')
   resetVideos(blockObj);   
end

% Get all unique camera sources
uSource = unique({blockObj.Videos.Source});
if numel(uSource) < 1
   fprintf(1,'No video sources detected.\n');
   flag = true;
   return;
end

out_path = blockObj.Paths.Video.dir;
expr = blockObj.Paths.Video.f_expr; %Video_%s_%s.%s
fprintf(1,repmat('\b',1,26));

VideoOffset = [];
% NeuOffset = [];

nSource = numel(uSource);
keyIndex = 0;

for i = 1:nSource
   % Create "camera" object for each source, and iterate to export trials
   
   Series = FromSame(blockObj.Videos,uSource{i});
   sourceIndex = find(strcmp(blockObj.Meta.Video.(cvar),uSource{i}),1,'first');
   if ~Series(1).Masked
      Idle(Series);
      continue;
   end
   
   fprintf(1,'<strong>%s</strong>...000%%\n',uSource{i});
   
   % Get array of "series" trial times
   camObj = nigeLab.libs.nigelCamera(blockObj,uSource{i});
   Ready(Series,true);
   neuOff = Series(1).NeuOffset;
   ts_onset = tStart + neuOff; % Neural offset is same for all
   ts_offset = tStop + neuOff;
   if ~isExtracted
      blockObj.TrialVideoOffset(sourceIndex,:) = reshape(ts_onset,1,numel(ts_onset));
   else
      ts_onset = ts_onset + blockObj.TrialVideoOffset(sourceIndex,:);
      blockObj.TrialVideoOffset(sourceIndex,:) = reshape(ts_onset,1,numel(ts_onset));
   end
   nTrial = numel(tStart);
   for k = 1:nTrial
      if isnan(ts_onset(k)) || isinf(ts_onset(k))
         continue; % Then skip this trial (only can happen if 'Init' used)
      end
      keyIndex = keyIndex + 1;
      blockObj.TrialIndex = k; % Update block trial index
      camObj.Time = ts_onset(k);

      VideoOffset = [VideoOffset, tStart(k)]; %#ok<AGROW>
%       NeuOffset = [NeuOffset, neuOff];  %#ok<AGROW>
      VFR = Series(camObj.Index).V;
      VFR.CurrentTime = camObj.Time - Series(camObj.Index).VideoOffset;
      trialStr = sprintf('Trial-%03g',k);
      fname = fullfile(out_path,sprintf(expr,uSource{i},trialStr,'MP4'));
      % Create video writer object for a new file
      if ~isExtracted
         vidWriter = VideoWriter(fname,'MPEG-4'); %#ok<TNMLP>
         vidWriter.FrameRate = Series(camObj.Index).fs;
         vidWriter.Quality = 100;
         open(vidWriter); % Open video file
         data = [];
         iCur = camObj.Index;
         while (camObj.Time < ts_offset(k))
            data = [data, camObj.Time-ts_onset(k)]; %#ok<AGROW>
            C = readFrame(VFR); % Reads in current frame
            writeVideo(vidWriter,C(Series(camObj.Index).ROI{:})); % Writes to vidWriter with `fname` @ `outpath`
            camObj.Time = VFR.CurrentTime + camObj.VideoOffset;
            if camObj.Index ~= iCur
               VFR = Series(camObj.Index).V;
               VFR.CurrentTime = camObj.Time-Series(camObj.Index).VideoOffset;
            end
         end 

         parseVidFileName(blockObj,fname,keyIndex,true);
         fname_t = fullfile(out_path,sprintf(expr,uSource{i},trialStr,'mat'));
         nigeLab.libs.DiskData('MatFile',fname_t,data,...
            'access','w','size',size(data),'class',class(data),...
            'overwrite',true);   
         close(vidWriter);       % Close video file
         delete(vidWriter);  
      else
         parseVidFileName(blockObj,fname,keyIndex,true);
      end
      fprintf(1,'\b\b\b\b\b%03g%%\n',round(k/nTrial * 100));
   end
   for k = 1:numel(Series)
      Series(k).Exported = true;
   end
   Idle(Series);
   delete(camObj);
   fprintf(1,repmat('\b',1,numel(uSource{i})+8));
end
blockObj.HasVideoTrials = true;

% Update Videos to reference the extracted Trials
blockObj.Paths.V.Orig = blockObj.Paths.V; % Save struct with "old" vid info
[blockObj.Paths.V.Root,blockObj.Paths.V.Folder] = ...
   fileparts(blockObj.Paths.Video.dir);

idx = regexp(blockObj.Paths.Video.f_expr,'\%s');
wc = repmat({'*'},1,numel(idx)-1);
blockObj.Paths.V.Match = sprintf(blockObj.Paths.Video.f_expr,wc{:},'MP4');
f_search = fullfile(...
   blockObj.Paths.V.Root,...
   blockObj.Paths.V.Folder,...
   blockObj.Paths.V.Match);
blockObj.Paths.V.F = dir(f_search);
% Make "Videos" fieldtype object or array
delete(blockObj.Videos);
blockObj.Videos(:) = []; % Remove all previous videos.
blockObj.Videos = nigeLab.libs.VideosFieldType(blockObj);

if isempty(blockObj.Videos)
   blockObj.TrialIndex = 1;        % Reset trial index
   blockObj.CurNeuralTime = 0;
else
   blockObj.VideoIndex = 1;        % Reset video index
   blockObj.VideoSourceIndex = 1;  % Initialize "Video Source" index
   blockObj.TrialIndex = str2double(...
      blockObj.Meta.TrialVideo.(blockObj.Pars.Video.MovieIndexVar){1});
   % Set current neural time to first video time
   blockObj.CurNeuralTime = blockObj.Videos(1).tNeu(1);   
end

setVideoOffsets(blockObj.Videos,VideoOffset);
% NeuOffset = num2cell(NeuOffset);
% [blockObj.Videos.NeuOffset] = deal(NeuOffset{:});

% Note: the following two steps are unnecessary--we extract frame times
%       as each frame is put into the new video.
% uView = unique({blockObj.Videos.Source});
% initRelativeTimes(blockObj.Videos,uView);

fprintf(1,'<strong>complete</strong>\n');
nigeLab.sounds.play('bell',0.75,-25);
flag = true;


end