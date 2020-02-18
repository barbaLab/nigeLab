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
   end
   
   % TRANSIENT,HIDDEN,PUBLIC
   properties(Transient,Hidden,Access=public)
      Block_                           % nigeLab.Block "Parent" of parent
      Time_                            % Matrix bounding different videos' time vectors
      TimeAxesObj_                     % Container of .Parent
   end
   
   % ABORTSET,HIDDEN,TRANSIENT,PUBLIC
   properties(AbortSet,Hidden,Transient,Access=public)
      SeriesIndex_   (1,1) double = 1  % Container of .Index property
      SeriesList_                      % Container of .Series
      SeriesTime_    (1,1) double = 0  % Container of .Time property
      Source_              char        % Container of .Source property
      VideoIndex_    (1,1) double = 1  % Index of current video from obj.Block.Videos
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
         obj.SeriesIndex_ = value;
         obj.VideoIndex_ = obj.SeriesList_(value).VideoIndex;
         obj.TimeAxesObj_.VidGraphicsObj.SeriesIndex_ = value;
         obj.TimeAxesObj_.VidGraphicsObj.VideoIndex_ = obj.VideoIndex_;
         obj.TimeAxesObj_.VidGraphicsObj.FrameTime = ...
            obj.SeriesTime_ - obj.Block_.Videos(obj.VideoIndex_).VideoOffset;
         obj.TimeAxesObj_.VidGraphicsObj.NeuTime = ...
            obj.SeriesTime_ + obj.TimeAxesObj_.VidGraphicsObj.NeuOffset + ...
            obj.TimeAxesObj_.VidGraphicsObj.TrialOffset;
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
         if isempty(idx)
            return;
         end
         obj.Index = idx;
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
         if isempty(idx)
            return;
         end
         obj.SeriesTime_ = value;
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
   methods (Access=?nigeLab.libs.TimeScrollerAxes)
      % Class constructor
      function obj = nigelCamera(timeAxesObj,varargin)
         %NIGELCAMERA  Constructor for object to reference video series
         %   
         %  cameraObj = nigeLab.libs.nigelCamera(timeAxesObj);
         %  * Constructor restricted to calls from `TimeScrollerAxes`
         %
         %  cameraObj = nigeLab.libs.nigelCamera(timeAxesObj,varargin);
         
         obj.Parent = timeAxesObj;
         obj.Block_ = timeAxesObj.Block;
         obj.Series = timeAxesObj.VidGraphicsObj.SeriesList;
         
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
         
         idx = find(seriesTimeInfo(:,1) & ...
                   (seriesTime >= seriesTimeInfo(:,2)) & ...
                   (seriesTime <  seriesTimeInfo(:,3)),1,'first');
      end
   end
   % % % % % % % % % % END METHODS% % %
end

