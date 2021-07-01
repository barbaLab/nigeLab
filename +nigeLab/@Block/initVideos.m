function flag = initVideos(blockObj,forceNewParams)
%INITVIDEOS Initialize Videos struct for nigeLab.Block class object
%
%  flag = initVideos(blockObj); Returns false if initialization fails
%
%  flag = blockObj.initVideos(true);
%  --> forceNewParams is false by default; this forces to update the video
%      parameter struct from the +defaults/Videos.m file

if nargin < 2
   forceNewParams = true;
end
if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      flag = flag && initVideos(blockObj(i),forceNewParams);
   end
   return;
else
   flag = false; % Initialize to false
end
if isempty(blockObj)
   flag = true;
   return;
elseif ~isvalid(blockObj)
   flag = true;
   return;
end
% Get parameters associated with video
if forceNewParams
   blockObj.updateParams('Video','Direct');
elseif ~isfield(blockObj.Pars,'Video')
   blockObj.updateParams('Video','KeepPars');
end

[fmt,idt,~] = getDescriptiveFormatting(blockObj);

if ~blockObj.Pars.Video.HasVideo
   flag = true;
   if blockObj.Verbose
      nigeLab.utils.cprintf(fmt,'%s[BLOCK/INITVIDEOS]: ');
      nigeLab.utils.cprintf(fmt(1:(end-1)),'(%s)',blockObj.Name);
      nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
         '\t%s(Skipped video initialization)\n',idt);
   end
   return;
end
Pars = blockObj.Pars.Video;
ext = blockObj.Pars.Video.FileExt;
% Initialize Videos version of Paths
Metas = cellfun(@(v) blockObj.Meta.(v),Pars.UniqueKey.vars,'UniformOutput',false);
Key = strjoin(Metas,Pars.UniqueKey.cat);
Key([1 end+1]) = '*';
Videos = [];
for ii =1:numel(Pars.VidFilePath)
    Videos = [ Videos,dir(fullfile(Pars.VidFilePath{ii},'**',Key))];
end

if isempty(Videos)
   if Pars.UseVideoPromptOnEmpty
      selpath = uigetdir(Pars.VidFilePath{1},...
         sprintf('Select VIDEO for %s',blockObj.Name));
      if fName==0
         nigeLab.utils.cprintf(fmt,...
            '%s[DOVIDINFOEXTRACTION]: No video selected for Block %s\n',...
            idt,blockObj.Name);
        dbstack(); % See note below:
         return;    
      end
      Pars.VidFilePath = selpath;
      for ii =1:numel(Pars.VidFilePath)
          Videos = [ Videos,dir(fullfile(Pars.VidFilePath{ii},'**',[uKey '*' Pars.FileExt]))];
      end
      
      if isempty(Videos)
         % at this point if no videos are found, naming might be off. 
         % Best should be to run here the naming configurator but i cannot
         % be bothered. Will do in the future. Let's throw an error
         % instead.
          nigeLab.utils.cprintf(fmt,...
            ['%s[DOVIDINFOEXTRACTION]: No video was found for Block %s.'...
            '\nCheck the configuration file for the correct naming.\n'],...
            idt,blockObj.Name);
         dbstack(); % See note below:
         return;    
      end
      
   else
      flag = true; % Indicate this is fine; there are just no videos for 
                   % this particular Block (probably from a batch
                   % initialization where some blocks have video and others
                   % do not)
      return;
   end
end

paths = {};
toOrder = false(1,numel(Videos));
for ii=1:numel(Videos)
    if Videos(ii).isdir
        % One camera per folder
        p_ = dir(fullfile(Videos(ii).folder,Videos(ii).name,['*' ext]));
        p_ = arrayfun(@(x) fullfile(x.folder,x.name),p_,'UniformOutput',false);
        i = Pars.CustomSort(p_);
        paths =[paths {p_(i)}];
        
        fName = Videos(ii).name;
        NamingConvention = Pars.NamingConvention;
        NamingConvention(contains(NamingConvention,Pars.IncrementingVar)) = [];
    else
        
        % Let's check the file extension, group files and make cameras
        [path,fName,thisExt] = fileparts(Videos(ii).name);
        if ~strcmpi(thisExt,ext)
            exclude(ii) = true;
            continue;
        end
        NamingConvention = Pars.NamingConvention;
        toOrder(ii) = true;
        paths =[paths {fullfile(Videos(ii).folder,Videos(ii).name)}];
    end %fi

        nameParts=strsplit(fName,[Pars.Delimiter, {'.',' '}]);

         regExpStr = sprintf('\\%c\\w*',...
            Pars.IncludeChar);
         splitStr = regexp(NamingConvention,regExpStr,'match');
         
         
         % Find which delimited elements correspond to variables that
         % should be included by looking at the leading character from the
         % defaults.Block template string:
         incVarIdx = find(~cellfun(@isempty,splitStr));
         exclVarIdx = find(cellfun(@isempty,splitStr));
         splitStr = [splitStr{:}];  
         

         
          if (numel(incVarIdx) + numel(exclVarIdx)) ~= numel(nameParts)
               % run nanming interface
         end
         
           
         % Find which set of variables (the total number available from the
         % name, or the number set to be read dynamically from the naming
         % convention) has fewer elements, and use that to determine how
         % many loop iterations there are:
         nMin = min(numel(incVarIdx),numel(nameParts));
         
         % Create a struct to allow creation of dynamic variable name
         % dictionary. Make sure to iterate on 'splitStr', and not
         % 'nameParts,' because variable assignment should be decided by
         % the string in namingConvention property.
         for jj=1:nMin
            varName = deblank( splitStr{jj}(2:end));
            meta.(varName) = nameParts{incVarIdx(jj)};
         end
         
         % For each "special" field, use combinations of variables to
         % produce other metadata tags. See '~/+nigeLab/+defaults/Block.m`
         % for more details
         for jj = 1:numel(Pars.SpecialMeta.SpecialVars)
            f = Pars.SpecialMeta.SpecialVars{jj};
            if ~isfield(meta,f)
               if ~isfield(Pars.SpecialMeta,f)
                  link_str = sprintf('nigeLab.defaults.%s','Video');
                  error(['nigeLab:' mfilename ':BadConfig'],...
                     ['%s is configured to use %s as a "special field,"\n' ...
                     'but it is not configured in %s.'],...
                     nigeLab.utils.getNigeLink(...
                     'nigeLab.Block','initVideos'),...
                     f,nigeLab.utils.getNigeLink(link_str));
               end %fi
               if isempty(Pars.SpecialMeta.(f).vars)
                  warning(['nigeLab:' mfilename ':PARSE'],...
                     ['No <strong>%s</strong> "SpecialMeta" configured\n' ...
                           '-->\t Making random "%s"'],f,f);
                  meta.(f) = nigeLab.utils.makeHash();
                  meta.(f) = meta.(f){:};
               else
                  tmp = cell(size(Pars.SpecialMeta.(f).vars));
                  for i = 1:numel(Pars.SpecialMeta.(f).vars)
                     tmp{i} = meta.(Pars.SpecialMeta.(f).vars{i});
                  end %i
                  meta.(f) = strjoin(tmp,Pars.SpecialMeta.(f).cat);
               end %fi
            end% fi
         end %jj       
         
       Meta{ii} = meta;  
         
end %ii
GroupingField = Pars.NamingConvention{strcmp(Pars.GroupingVar,cellfun(@(v) v(2:end),Pars.NamingConvention,'UniformOutput',false))}(2:end);
CounterField = Pars.NamingConvention{strcmp(Pars.IncrementingVar,cellfun(@(v) v(2:end),Pars.NamingConvention,'UniformOutput',false))}(2:end);


if all(~toOrder)
    Meta_ = cellfun(@(M,p) repmat(M,size(p)),Meta,paths,'UniformOutput',false);
elseif all(toOrder)
    toOrder = find(toOrder);
    AllMetastoOrder = [Meta{toOrder}];
    GroupingLables = {AllMetastoOrder.(GroupingField)};
    uLabels = unique(GroupingLables);
    
    perm = @(x,i)x(i);
    OrderedPaths = cell(1,numel(uLabels));
    
    for ii=1:numel(uLabels)
        Idx = (strcmp(GroupingLables, uLabels{ii}));
        Counter = {AllMetastoOrder(Idx).(CounterField)};
        [~,i]=sort(Counter);
        paths{ii} = arrayfun(@(d) fullfile(d.folder,d.name),Videos(perm(toOrder(Idx),i)),'UniformOutput',false);
        Meta_{ii} = [Meta{Idx}];
    end
    paths(ii+1:end) = [];
else
    Ordered = find(~toOrder);
    OrderedMeta = [Meta{Ordered}];
    OrderedGroups = {OrderedMeta.(GroupingField)};
    
    toOrder = find(toOrder);
    AllMetastoOrder = [Meta{toOrder}];
    GroupingLables = {AllMetastoOrder.(GroupingField)};
    uLabels = unique(GroupingLables);
    
    perm = @(x,i)x(i);
    OrderedPaths = cell(1,numel(uLabels));
   
    for ii=1:numel(uLabels)
        Idx = (strcmp(GroupingLables, uLabels{ii}));
        Counter = {AllMetastoOrder(Idx).(CounterField)};
        [~,i]=sort(Counter);
        thisLabel = uLabels(ii);
        ordIdx = Ordered(strcmp(OrderedGroups,uLabels(ii)));
        paths{ordIdx} = [paths{ordIdx};...
            arrayfun(@(d) fullfile(d.folder,d.name),Videos(perm(toOrder(Idx),i)),'UniformOutput',false)];
        Meta_{ii} = [repmat(Meta{ordIdx},size(paths{ordIdx})) [Meta{perm(toOrder(Idx),i)}]];
    end
    paths(toOrder) = [];
end


paths = cellfun(@unique,paths,'UniformOutput',false);
for ii = 1:size(paths,2)
    cam(ii) = nigeLab.libs.nigelCamera(blockObj,paths{ii});
    f = fieldnames(Meta{ii});
    for ff = f'
        [cam(ii).Meta.(ff{:})] = deal(Meta_{ii}.(ff{:}));
    end
end


blockObj.Cameras = cam;
flag = true;
end