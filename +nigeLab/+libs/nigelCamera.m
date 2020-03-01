classdef nigelCamera < matlab.mixin.SetGet
   %NIGELCAMERA  Object with data about all videos from a source camera
   %   
   %  cameraObj = nigeLab.libs.nigelCamera(timeAxesObj);
   %  * Constructor is restricted to be called from `TimeScrollerAxes`
   
   % % % PROPERTIES % % % % % % % % % %     
   % ABORTSET,DEPENDENT,TRANSIENT,PUBLIC
   properties (AbortSet,Dependent,Transient,Access=public)
      Series                           % Array of nigeLab.libs.VideosFieldType objects
      Source         char              % From nigeLab.libs.VidGraphics object
      Time     (1,1) double = 0        % Current "Series Time"
   end
   
   % DEPENDENT,TRANSIENT,PUBLIC
   properties (Dependent,Transient,Access=public)
      Index    (1,1) double = 1     % Index to current object within obj.Series
      Parent                        % Parent nigeLab.libs.TimeScrollerAxes object
      SeriesTime_ (1,1) double = 0  % "Dependent" container for .Time
   end
   
   % TRANSIENT,HIDDEN,PUBLIC
   properties(Transient,Hidden,Access=public)
      Block_                           % nigeLab.Block "Parent" of parent
      NeuTime_       (1,1) double = 0  % Current neural time
      Time_                            % Matrix bounding different videos' time vectors
      TimeAxesObj_                     % Container of .Parent
   end
   
   % ABORTSET,HIDDEN,TRANSIENT,PUBLIC
   properties(AbortSet,Hidden,Transient,Access=public)
      SeriesIndex_   (1,1) double = 1  % Container of .Index property
      SeriesList_                      % Container of .Series
      SeriesTime__   (1,1) double = 0  % Container of .SeriesTime_ property
      Source_              char        % Container of .Source property
      VideoIndex_    (1,1) double = 1  % Index of current video from obj.Block_.Videos
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded)
   methods
      % % % (DEPENDENT) GET/SET.PROPERTY METHODS % % % % % % % % % % % %
      % [DEPENDENT]  .Index property references .SeriesIndex_
      function value = get.Index(obj)
         %GET.INDEX  References .SeriesIndex_
         value = obj.SeriesIndex_;
      end
      function set.Index(obj,value)
         %SET.INDEX  Assigns .SeriesIndex_
         
         
         % Set Neural Time using index for offset etc. from old video

         obj.SeriesIndex_ = value;
         
         % Get offsets for current video
         trialOffset = obj.SeriesList_(value).TrialOffset;
         videoOffset = obj.SeriesList_(value).VideoOffset;
         neuOffset = obj.SeriesList_(value).NeuOffset;
         
         % Get sample rate
         fs = obj.SeriesList_(value).fs;
         
         % Compute frame time
         frameTime = max(obj.NeuTime_-videoOffset+neuOffset+trialOffset,0);
         
         % Compute frame index
         frameIndex = max(round(frameTime * fs)+1,1);
         
         % Compute series time
         seriesTime = frameTime + videoOffset;
         
         obj.SeriesTime_ = seriesTime;
         obj.VideoIndex_ = obj.SeriesList_(value).VideoIndex;
         obj.Block_.VideoIndex = obj.VideoIndex_;
         
         VG = obj.TimeAxesObj_.VidGraphicsObj; 
         VG.SeriesIndex_ = value;
         
         obj.SeriesList_(value).V.CurrentTime = frameTime; % Update frame time
         
         % Set FrameIndex, which will cause some flags to be computed about
         % whether buffer needs to be updated etc.
         obj.TimeAxesObj_.VidGraphicsObj.FrameIndex = frameIndex;
         if ~isstruct(obj.TimeAxesObj_)
            neuTimeNew = setFrame(obj.TimeAxesObj_.VidGraphicsObj);
            updateTimeLabelsCB(obj.TimeAxesObj_.VidGraphicsObj,...
               seriesTime,neuTimeNew);
            if ~isempty(obj.SeriesList_(value).ROI)
               updateBuffer(VG);
               setFrame(VG);
            end
            drawnow;
         end
      end
      
      % [DEPENDENT]  .Parent property references .TimeAxesObj_
      function value = get.Parent(obj)
         value = obj.TimeAxesObj_;
      end
      function set.Parent(obj,value)
         obj.TimeAxesObj_ = value;
      end
      
      % [DEPENDENT]  .Series property references .SeriesList_
      function value = get.Series(obj)
         %GET.SERIES  References .TimeAxesObj_ to get list of Video objects
         value = obj.SeriesList_;
      end
      function set.Series(obj,value)
         %SET.SERIES  Ensure that .Time_ is updated
         obj.SeriesList_ = value;
         newTimeInfo = obj.Time_; % Updated by set.SeriesList_
         idx = nigeLab.libs.nigelCamera.getSeriesIndex(...
            obj.SeriesTime_,newTimeInfo);
         if ~isempty(obj.TimeAxesObj_)
            VG = obj.TimeAxesObj_.VidGraphicsObj;  
            VG.SeriesIndex_ = idx;
            if isempty(idx)
               return;
            end
            obj.SeriesIndex_ = idx;
            VG.FrameIndex_ = -inf;
            VG.NewVideo_ = true;
         elseif ~isempty(idx)
            obj.SeriesIndex_ = idx;
         end
      end
      
      % [DEPENDENT]  .SeriesTime_ is an intermediate dependent property
      function value = get.SeriesTime_(obj)
         %GET.SERIESTIME_  Intermediate to .Time and .SeriesTime__
         %
         %  value = get(obj,'SeriesTime_');
         %  --> Doesn't trigger all the cascades of .Time
         value = obj.SeriesTime__;
      end
      function set.SeriesTime_(obj,value)
         %SET.SERIESTIME_  Intermediate for .Time and .SeriesTime__
         %
         %  set(obj,'SeriesTime_',value);
         
         % Set value
         obj.SeriesTime__ = value;
         
         % Compute neural time
         neuOffset = obj.SeriesList_(obj.SeriesIndex_).NeuOffset;
         trialOffset = obj.SeriesList_(obj.SeriesIndex_).TrialOffset;
         obj.NeuTime_ = value - neuOffset - trialOffset;
      end
      
      % [DEPENDENT]  .Source references .TimeAxesObj_.VidGraphicsObj
      function value = get.Source(obj)
         %GET.SOURCE  References .TimeAxesObj_.VidGraphicsObj.VideoSource
         value = obj.Source_;
      end
      function set.Source(obj,value)
         %SET.SOURCE  Assign camera "source" (char array)
         obj.Source_ = value;
         obj.TimeScrollerAxes_.VidGraphicsObj.VideoSource_ = value;
      end
      
      % [DEPENDENT]  .Time references .SeriesTime_
      function value = get.Time(obj)
         %GET.TIME  Returns .Time (references .SeriesTime_)
         value = obj.SeriesTime_;
      end
      function set.Time(obj,value)
         %SET.TIME  Assign new .Time (updates .Index based on .Time_)
         
         idx = nigeLab.libs.nigelCamera.getSeriesIndex(value,obj.Time_);
         if isempty(idx) % Returns empty if "out of bounds"
            return;
         end
         obj.SeriesTime_ = value;
         
         % Set Index (dependent property that updates the rest)
         obj.Index = idx;
      end
      % % % % % % % % % % END (DEPENDENT) GET/SET.PROPERTY METHODS % % %
      
      % % % (NON-DEPENDENT) SET.PROPERTY METHODS % % % % % % % % % % % % 
      function set.SeriesList_(obj,value)
         %SET.SERIESLIST_  Ensure time vector matches
         obj.SeriesList_ = value;
         parseTime(obj);
      end
      % % % % % % % % % % END (NON-DEPENDENT) SET.PROPERTY METHODS % % %
   end
   
   % RESTRICTED:nigeLab.libs.TimeScrollerAxes (constructor)
   methods (Access={?nigeLab.libs.TimeScrollerAxes,?nigeLab.Block,?nigeLab.nigelObj})
      % Class constructor
      function obj = nigelCamera(timeAxesObj,varargin)
         %NIGELCAMERA  Constructor for object to reference video series
         %   
         %  cameraObj = nigeLab.libs.nigelCamera(timeAxesObj);
         %  * Constructor restricted to calls from `TimeScrollerAxes`
         %
         %  cameraObj = nigeLab.libs.nigelCamera(timeAxesObj,varargin);
         
         if isa(timeAxesObj,'nigeLab.libs.TimeScrollerAxes')
            obj.Parent = timeAxesObj;
            obj.Block_ = timeAxesObj.Block;
            obj.Series = timeAxesObj.VidGraphicsObj.SeriesList;
         elseif isa(timeAxesObj,'nigeLab.Block')
            blockObj = timeAxesObj;
            if nargin < 2
               error(['nigeLab:' mfilename ':TooFewInputs'],...
                  ['[NIGELCAMERA]: If first input is Block, ' ...
                  'at least two inputs are required.']);
            end            
            
            s = varargin{1};
            varargin(1) = [];
            if isa(s,'nigeLab.libs.VideosFieldType')
               obj.Series = s;
               src = s(1).Source;
            elseif isa(s,'char')
               obj.Series = FromSame(blockObj.Videos,s);
               src = s;
            else
               error(['nigeLab:' mfilename ':BadClass'],...
                  ['\t\t->\t<strong>[NIGELCAMERA]</strong>: ' ...
                  'When first input is `nigeLab.Block`, second '...
                  'argument should be member of one of the following:\n' ...
                  '\t\t\t->\t<strong>nigeLab.libs.VideosFieldType</strong>\n' ...
                  '\t\t\t->\t<strong>char</strong>\n']);
            end
            obj.Parent = struct('VidGraphicsObj',struct(...
               'SeriesIndex_',1,...
               'VideoIndex_',1,...
               'VideoSource_',src,...
               'FrameTime',0,...
               'NeuTime',0));
         else
            error(['nigeLab:' mfilename ':BadClass'],...
               '[NIGELCAMERA]: Invalid input class (''%s'')\n',...
               class(timeAxesObj));
         end
         
         % No error-checking here
         for iV = 1:2:numel(varargin)
            obj.(varargin{iV}) = varargin{iV+1};
         end
      end
   end
   
   % PROTECTED
   methods (Access=protected)
      function parseTime(obj)
         %PARSETIME   Parses concatenated vector for .Time_ property
         %
         %  parseTime(obj);
         
         % Do not update if .Series is empty
         if isempty(obj.Series)
            return;
         end
         
         obj.Time_ = zeros(numel(obj.Series),3);
         for i = 1:numel(obj.Series)
            t = obj.Series(i).tVid;
            obj.Time_(i,:) = [obj.Series(i).Masked, min(t), max(t)];
         end
      end
   end
   
   % PROTECTED,STATIC
   methods (Static,Access=protected)
      function idx = getSeriesIndex(seriesTime,seriesTimeInfo)
         %GETSERIESINDEX  Returns index based on series start/stop times
         %
         %  idx = nigeLab.libs.nigelCamera(seriesTime,seriesTimeInfo);
         %
         %  seriesTime : Scalar -- time to update series to
         %  seriesTimeInfo : nSeries x 3 matrix
         %     * Column 1 -- "Enabled" (1) or "Disabled" (0)
         %     * Column 2 -- Start times (SERIES) (greater than or equals)
         %     * Column 3 -- Stop times (SERIES)  (less than)
         %
         
         if isempty(seriesTime) || isempty(seriesTimeInfo)
            idx = [];
            return;
         end
         
         % Uses mask:
         % idx = find(seriesTimeInfo(:,1) & ...
         %           (seriesTime >= seriesTimeInfo(:,2)) & ...
         %           (seriesTime <  seriesTimeInfo(:,3)),1,'first');
         
         % Disregards mask:
         idx = find( ...
                   (seriesTime >= seriesTimeInfo(:,2)) & ...
                   (seriesTime <  seriesTimeInfo(:,3)),1,'first');
      end
   end
   % % % % % % % % % % END METHODS% % %
end

