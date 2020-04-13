function rc2Block(blockObj)
%% RC2BLOCK    Convert from RC format to BLOCK format
%
%  RC2BLOCK(blockObj);
%
%  Note: This converison function checks if files exist in each of the
%           folders to which "converted" data is to be moved. If those
%           folders have any *.mat files in them, then the corresponding
%           folder datatype "conversion" is skipped.
%
%  --------
%   INPUTS
%  --------
%  blockObj : Current nigeLab.Block

%% Check compatibility
REQUIRED_FIELD_NAMES = {'DigIO','ScoredEvents','Raw','CAR','Spikes','Clusters'}; % Should be included in all +workflow functions
blockObj.checkCompatibility(REQUIRED_FIELD_NAMES);

%% Get properties of interest
p = blockObj.Pars.Block.PathExpr;
recFile = blockObj.RecFile;
animalLoc = blockObj.AnimalLoc;

%% Parse input
% Make sure that input file exists
if exist(recFile,'file')==0
   error('No file: %s\n',recFile);
end

% Make sure that output location exists
if exist(animalLoc,'dir')==0
   fprintf(1,'%s does not exist. New save location created.\n',animalLoc);
   mkdir(animalLoc);
end



nigeLab.utils.cprintf('SystemCommands','-->\tConverting %s\n',recFile);
nigeLab.utils.cprintf('SystemCommands','\t-->\tAt: %s\n',animalLoc);


%% Get file structure from file name basically

[path,fname,~] = fileparts(recFile);
blockName = strsplit(fname,'_');
blockName = strjoin(blockName(1:4),'_');
block_in = fullfile(path);
block_out = fullfile(animalLoc,blockName);
if exist(block_out,'dir')==0
   mkdir(block_out);
end

%% Move digital streams
% Make the new '_Digital' folder and move files
f_in = nigeLab.utils.getUNCPath(fullfile(block_in,[blockName '_Digital']));
f_out = nigeLab.utils.getUNCPath(fullfile(block_out,p.DigIO.Folder));

F = dir(fullfile(f_in,[blockName '*.mat']));
for iF = 1:numel(F)
   str_info = strsplit(F(iF).name(1:(end-4)),'_');
   dtype = str_info{end};
   if ismember(dtype,{'Beam','Press','Paw'})
      in = load(nigeLab.utils.getUNCPath(fullfile(F(iF).folder,F(iF).name)),'data');
      data = in.data;
      if strcmpi(dtype,'Paw')
         save(nigeLab.utils.getUNCPath(fullfile(block_out,p.VidStreams.Folder,...
            sprintf(p.VidStreams.File,'Front-Paw_Likelihood-Marker',1,'mat'))),'data','-v7.3');
      else
         save(fullfile(f_out,sprintf(p.DigIO.File,'DigIn',dtype)),'data','-v7.3');
      end
      
   elseif strcmpi(dtype,'Scoring')
      in = load(nigeLab.utils.getUNCPath(fullfile(F(iF).folder,F(iF).name)),'behaviorData');
      if ~isfield(in,'behaviorData')
         error('Weird "scoring" file. Should have behaviorData. Check configuration.');
      else
         [fname,X] = nigeLab.workflow.behaviorData2BlockEvents(in.behaviorData,...
            fullfile(block_out,p.ScoredEvents.Folder),...
            p.ScoredEvents.File);
      end
      
   elseif strcmpi(dtype,'VideoAlignment')
      
      in = load(nigeLab.utils.getUNCPath(fullfile(F(iF).folder,F(iF).name)),'VideoStart');
      if ~isfield(in,'VideoStart')
         error('Weird Alignment scoring file. Check configuration.');
      end
      tmpVidStart = in.VideoStart; % Hold until behaviorData is done
   end
   
end

% After 'Header' has been made
if exist('tmpVidStart','var')==0
   tmpVidStart = 0;
end

for i = 1:numel(fname)
   data = X{i};
   if i > 1 % For everything but 'Header'
      data(:,4) = data(:,4) - tmpVidStart; % Remove video offset from times
   end
   out = nigeLab.libs.DiskData('Event',fname{i},data,...
      'Complete',zeros(1,1,'int8'));
end
   
out_name =  nigeLab.utils.getUNCPath(fullfile(block_out,...
   p.ScoredEvents.Folder,...
   sprintf(p.ScoredEvents.File,'Header')));
out = nigeLab.libs.DiskData('Event',out_name,'access','w',...
   'Complete',zeros(1,1,'int8'),'Index',1);
out.data(1,4) = tmpVidStart;


%% Move filtered and raw streams
% Raw
f_in = nigeLab.utils.getUNCPath(fullfile(block_in,[blockName '_RawData']));
f_out = nigeLab.utils.getUNCPath(fullfile(block_out,p.Raw.Folder));
Fout = dir(fullfile(f_out,'*.mat'));
if isempty(Fout)
   F = dir(fullfile(f_in,[blockName '*.mat']));
   for iF = 1:numel(F)
      str_info = strsplit(F(iF).name(1:(end-4)),'_');
      ch = str_info{end};
      probe = str_info{end-2}(2);

      in = load(fullfile(F(iF).folder,F(iF).name),'data');
      data = in.data;
      save(fullfile(f_out,sprintf(p.Raw.File,probe,ch)),'data','-v7.3');
   end
end


% Filtered
f_in = nigeLab.utils.getUNCPath(fullfile(block_in,[blockName '_FilteredCAR']));
f_out = nigeLab.utils.getUNCPath(fullfile(block_out,p.CAR.Folder));

Fout = dir(fullfile(f_out,'*.mat'));
if isempty(Fout)
   F = dir(fullfile(f_in,[blockName '*.mat']));
   for iF = 1:numel(F)
      str_info = strsplit(F(iF).name(1:(end-4)),'_');
      ch = str_info{end};
      probe = str_info{end-2}(2);

      in = load(fullfile(F(iF).folder,F(iF).name),'data');
      data = in.data;
      save(fullfile(f_out,sprintf(p.CAR.File,probe,ch)),'data','-v7.3');
   end
end

%% Move Spikes & Clusters (those will have to be converted in a different way, later)
% Spikes
f_in = nigeLab.utils.getUNCPath(fullfile(block_in,[blockName '_wav-sneo_Car_Spikes']));
f_out = nigeLab.utils.getUNCPath(fullfile(block_out,sprintf(p.Spikes.Folder,'wav-sneo_CAR')));

Fout = dir(fullfile(f_out,'*.mat'));
if isempty(Fout)
F = dir(fullfile(f_in,[blockName '*.mat']));
   for iF = 1:numel(F)
      str_info = strsplit(F(iF).name(1:(end-4)),'_');
      ch = str_info{end};
      probe = str_info{end-2}(2);

      copyfile(fullfile(F(iF).folder,F(iF).name),...
         fullfile(f_out,sprintf(p.Spikes.File,probe,ch)));
   end
end

% Clusters
f_in = nigeLab.utils.getUNCPath(fullfile(block_in,[blockName '_wav-sneo_SPC_Car_Clusters']));
f_out = nigeLab.utils.getUNCPath(fullfile(block_out,sprintf(p.Clusters.Folder,'wav-sneo_SPC_CAR')));

Fout = dir(fullfile(f_out,'*.mat'));
if isempty(Fout)
F = dir(fullfile(f_in,[blockName '*.mat']));
   for iF = 1:numel(F)
      str_info = strsplit(F(iF).name(1:(end-4)),'_');
      ch = str_info{end};
      probe = str_info{end-2}(2);

      copyfile(fullfile(F(iF).folder,F(iF).name),...
         fullfile(f_out,sprintf(p.Clusters.File,probe,ch)));
   end
end

end