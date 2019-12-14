function flag = initEvents(blockObj)
%% INITEVENTS  Initialize events struct for nigeLab.Block class object
%
%  flag = INITEVENTS(blockObj);
%
% By: Max Murphy  v1.0  2019/01/11  Original version (R2017a)

%%
flag = false;
blockObj.updateParams('Event');
blockObj.updateParams('Video');
[uF,~,iU] = unique(blockObj.Pars.Event.Fields);
nEventTypes = numel(uF);
if nEventTypes == 0
   flag = true;
   disp('No EVENTS to initialize.');
   return;
end

% Initialize Events property as a struct
blockObj.Events = struct;
for ii = 1:nEventTypes
   % Find "Events" Fields that correspond to this "Field" 
   % (e.g. find all Events of 'ScoredEvents' field or 'DigEvents' field)
   idx = find(iU == ii);
   n = numel(idx);
   
   % k is just there to make it easy to understand the indexing
   k = 0;
   blockObj.Events.(uF{ii}) = nigeLab.utils.initChannelStruct('Events',n);
   % If there is a 'Scoring' type of Events, then they must be handled as
   % an exception; they will have 'Trial' and 'Header'
   if ~isempty(blockObj.Pars.Video.ScoringEventFieldName)
      if strcmpi(uF{ii},blockObj.Pars.Video.ScoringEventFieldName)
         % Add 'Trial' to 'ScoredEventFieldName'
         blockObj.Events.(uF{ii}) = nigeLab.utils.initChannelStruct('Events',n+2);
         k = k + 1; % k = 1
         blockObj.Events.(uF{ii})(k).name = 'Trial'; % "special" Events name
         blockObj.Events.(uF{ii})(k).status = false;
         
         
         % Add 'Header' to 'ScoringEventFieldName'
         k = k + 1; % k = 2
         blockObj.Events.(uF{ii})(k).name = 'Header'; % "special" Events name
         blockObj.Events.(uF{ii})(k).status = false;
         
      end
   end
   
   % k just accounts for the case that "special" 'Trial' Named Event was
   % incorporated for this Field
   for u = (1 + k):(n + k)
      blockObj.Events.(uF{ii})(u).name = blockObj.Pars.Event.Name{idx(u-k)};
      blockObj.Events.(uF{ii})(u).status = false;
   end
end
flag = true;
end