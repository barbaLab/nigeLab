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

blockObj.Videos = nigeLab.libs.VideosFieldType(blockObj);

% if blockObj.HasVideoTrials
%    if nargout > 0
%       varargout{1} = true;
%       if nargout > 1
%          varargout{2} = true;
%       end
%    end
%    return;
% end

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