function flag = doTrialVidExtraction(blockObj)
%DOTRIALVIDEXTRACTION  Extract Trial Videos 
%
%  flag = doTrialVidExtraction(blockObj);

if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      flag = flag && doTrialVidExtraction(blockObj(i));
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

% Detection stream parameters
detPars = blockObj.Pars.Event.TrialDetectionInfo;

% Get all the trial "start" times and "stop" times
fprintf(1,'\t\t->\t<strong>[DOTRIALVIDEXTRACTION]</strong>::%s: ',...
   blockObj.Name);
fprintf(1,'Formatting trial epochs...');
trialStarts = blockObj.Trial - blockObj.Pars.Video.PreTrialBuffer;
trial = getStream(blockObj,detPars.Name);
trialStops = nigeLab.utils.binaryStream2ts(trial.data,trial.fs,...
   detPars.Threshold,'Falling',detPars.Debounce) + ...
   blockObj.Pars.Video.PostTrialBuffer;


if numel(trialStarts) ~= numel(trialStops)
   error(['nigeLab:' mfilename ':BadTrialStructure'],...
      ['\t\t->\t[DOTRIALVIDEXTRACTION]: ' ...
      'Number of trialStarts (%g) does not ' ...
      'equal number of trialStops (%g)'],...
      numel(trialStarts),numel(trialStops));
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

nSource = numel(uSource);
for i = 1:nSource
   fprintf(1,'<strong>%s</strong>...000%%\n',uSource{i});
   
   % Create "camera" object for each source, and iterate to export trials
   camObj = nigeLab.libs.nigelCamera(blockObj,uSource{i});
   
   % Get array of "series" trial times
   Series = FromSame(blockObj.Videos,uSource{i});
   Ready(Series);
   ts_onset = trialStarts + Series(1).NeuOffset; % Neural offset is same for all
   ts_offset = trialStops + Series(1).NeuOffset;
   nTrial = numel(trialStarts);
   for k = 1:nTrial
      blockObj.TrialIndex = k; % Update block trial index
      camObj.Time = ts_onset(k);
      VFR = Series(camObj.Index).V;
      VFR.CurrentTime = camObj.Time - Series(camObj.Index).VideoOffset + ...
         Series(camObj.Index).TrialOffset;
      trialStr = sprintf('Trial-%03g',k);
      fname = fullfile(out_path,sprintf(expr,uSource{i},trialStr,'MP4'));
      % Create video writer object for a new file
      vidWriter = VideoWriter(fname,'MPEG-4'); %#ok<TNMLP>
      vidWriter.FrameRate = Series(camObj.Index).fs;
      vidWriter.Quality = 100;
      open(vidWriter); % Open video file
      data = [];
      iCur = camObj.Index;
      while (camObj.Time < ts_offset(k))
         data = [data, camObj.Time]; %#ok<AGROW>
         C = readFrame(VFR); % Reads in current frame
         writeVideo(vidWriter,C(Series(camObj.Index).ROI{:})); % Writes to vidWriter with `fname` @ `outpath`
         camObj.Time = VFR.CurrentTime + camObj.VideoOffset;
         if camObj.Index ~= iCur
            VFR = Series(camObj.Index).V;
            VFR.CurrentTime = camObj.Time-Series(camObj.Index).VideoOffset;
         end
      end 
      fname_t = fullfile(out_path,sprintf(expr,uSource{i},trialStr,'mat'));
      nigeLab.libs.DiskData('MatFile',fname_t,data,...
         'access','w','size',size(data),'class',class(data),...
         'overwrite',true);   
      close(vidWriter);       % Close video file
      delete(vidWriter);      
      fprintf(1,'\b\b\b\b\b%03g%%\n',round(k/nTrial * 100));
   end
   for k = 1:numel(Series)
      Series.Exported = true;
   end
   Idle(Series);
   delete(camObj);
   fprintf(1,repmat('\b',numel(uSource{i})+8));
end


% Update Videos to reference the extracted Trials
blockObj.HasVideoTrials = true;
[blockObj.Paths.V.Root,blockObj.Paths.V.Folder] = ...
   fileparts(blockOb.Paths.Video.dir);

idx = regexp(blockObj.Paths.Video.f_expr,'\%s');
wc = repmat({'*'},1,numel(idx)-1);
blockObj.Paths.V.Match = sprintf(blockObj.Paths.Video.f_expr,wc{:},'MP4');
fprintf(1,'<strong>complete</strong>\n');
flag = true;


end