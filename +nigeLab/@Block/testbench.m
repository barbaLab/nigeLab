function varargout = testbench(blockObj,varargin)
%TESTBENCH  For development to work with protected methods on ad hoc basis
%
%  varargout = testbench(blockObj,varargin);

varargout = cell(1,nargout);
if numel(blockObj) > 1
   for i = 1:size(blockObj,1)
      for j = 1:size(blockObj,2)
         tmp = cell(1,nargout);
         [tmp{:}] = testbench(blockObj(i,j),varargin{:});
         for k = 1:nargout
            varargout{k}{i,j} = tmp{k};
         end
      end
   end
   return;
end

% % % % Set all "snippet" values to zero for 'EventTimes' scoring % % % %
% if isfield(blockObj.Events,'ScoredEvents')
%    for i = 3:numel(blockObj.Events.ScoredEvents)
%       if ~isempty(blockObj.Events.ScoredEvents(i).data)
%          blockObj.Events.ScoredEvents(i).data.snippet(:) = 0;
%       end
%    end
% end

% % % % Re-initialize Videos property (for Trial Videos) % % % %
blockObj.Videos = nigeLab.libs.VideosFieldType(blockObj);

% % % % Re-parse Video metadata table % % % %
% updateParams(blockObj,'Block','Direct');
% updateParams(blockObj,'Video','Direct');
% updateParams(blockObj,'Event','Direct');
% parseNamingMetadata(blockObj);
% for i = 1:numel(blockObj.Videos)
%    parseVidFileName(blockObj,blockObj.Videos(i).Name);
% end

% % % % Re-initialize/link original Videos property % % % %
% initFlag = initVideos(blockObj);
% initFlag = initFlag && initEvents(blockObj);
% initFlag = initFlag && doEventDetection(blockObj);
% linkFlag = linkEventsField(blockObj,{'ScoredEvents','DigEvents'});

% if nargout > 0
%    varargout{1} = initFlag;
%    if nargout > 1
%       varargout{2} = linkFlag;
%    end
% end

end