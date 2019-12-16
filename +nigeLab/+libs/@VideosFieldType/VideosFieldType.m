classdef VideosFieldType
   % VIDEOSFIELDTYPE  Class for managing blockObj.Videos
   
   properties (GetAccess = public, SetAccess = private)
      Duration    % Duration of video (seconds)      
      FS          % Sample rate
      Height      % Height of video frame (pixels)
      Name        % Name of video file
      NFrames     % Total number of frames
      Width       % Width of video frame (pixels)
      Source      % Camera "view" (e.g. Door, Top, etc...)
      fname        % Full filename of video
   end
   
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      isConfigured % Flag indicating that pars.HasVideo is true or not
      meta         % Struct with metadata parsed from name and DynamicVars parameter
      pars         % Parameters struct
   end
   
   properties (Access = private)
      F           % Struct as returned by 'dir' regarding file info
   end
   
   methods (Access = public)
      % Class constructor
      function obj = VideosFieldType(F,params)
         % VIDEOSFIELDTYPE  Constructor for class to track video file info
         %
         %  obj = VideosFieldType(F); % Create FieldType for videos in
         %                            % 'dir' struct array (F)
         %  obj = VideosFieldType(F,params); % Specifies params struct (if
         %                                      not specified, uses
         %                                      defaults.Video() output
         %
         %  obj = VideosFieldType(dim1); % Empty column array 
         %  obj = VideosFieldType([dim1,dim2,...dimK]) % Empty matrix
         
         if nargin < 2
            if isstruct(F) % If no params input, use defaults
               params = nigeLab.defaults.Video();
               params.Vars = nigeLab.defaults.Event('VarsToScore');
               params.VarType = nigeLab.defaults.Event('VarType');
            else
               if isnumeric(F) % Allows array initialization
                  dims = F;
                  if numel(dims) < 2 % Can construct as VideosFieldType(dim1) or VideosFieldType ([d1,d2,...dn])
                     dims = [dims, 1];
                  end
                  obj = repmat(obj,dims);
                  return;
               else
                  error('Invalid input type: %s',class(F));
               end
            end
         elseif ~isstruct(params) % Can also construct as VideosFieldType(dim1,dim2);
            if isnumeric(params) && isnumeric(F)
               dims = [F, params];
               obj = repmat(obj,dims);
               return;
            else
               error('Invalid input combo: %s & %s', class(F),class(params));
            end
         end
         
         if numel(F) > 1 % Handle input array struct (such as returned by 'dir')
            obj = VideosFieldType(numel(F));
            for i = 1:numel(F)
               obj(i) = VideosFieldType(F(i),params);
            end
            return;
         end

         obj.F = F;
         obj.fname = getFile(obj);
         obj = obj.setPars(params);
         obj = obj.setVideoInfo;
      end
      
      % Return filename of video using UNC path
      function [filename,fileIsPresent] = getFile(obj)
         % GETFILE  Returns filename using UNC path convention
         
         if numel(obj) > 1
            filename = nigeLab.utils.initCellArray(numel(obj),1);
            fileIsPresent = false(numel(obj),1);
            for i = 1:numel(obj)
               [filename{i},fileIsPresent(i)] = getFile(obj(i));
            end
            return;
         end
         
         filename = nigeLab.utils.getUNCPath(fullfile(obj.F.folder,obj.F.name));
         fileIsPresent = ~isempty(filename);
      end
      
      % Return the times corresponding to each video frame
      function t = getFrameTimes(obj)
         if numel(obj) > 1
            t = cell(numel(obj),1);
            for i = 1:numel(obj)
               t{i} = getFrameTimes(obj(i));
            end
            return;
         end
         t = linspace(0,obj.Duration,obj.NFrames);
      end
      
      % Return "vid_F" dir struct for all objects in array
      function vid_F = getVid_F(varargin)
         % GETVID_F  Return "dir" struct for all objects in array
         
         if numel(varargin{1}) > 1
            vid_F = [];
            for i = 1:numel(obj)
               vid_F = [vid_F; getVid_F(varargin{1}(i))]; %#ok<*AGROW>
            end
            return;
         elseif numel(varargin) > 1
            vid_F = [];
            for i = 1:numel(varargin)
               vid_F = [vid_F; getVid_F(varargin{i})];
            end
            return;
         end
         
         vid_F = varargin{1}.F;
         
      end
      
      % Get VideoReader object
      function V = getVideoReader(obj)
         % GETVIDEOREADER  Returns video reader object
         
         % UserData field struct
         u = struct('user',obj.pars.User,...
            'varsToScore',obj.pars.VarsToScore,...
            'varType',obj.pars.VarType,...
            'meta',obj.meta);
         
         V = VideoReader(getFile(obj),'UserData',u);
      end
      
      % Get video source information
      function [source,signalIndex] = getVideoSourceInfo(obj)
         % GETVIDEOSOURCEINFO  Return view (e.g. 'Left-A') and signal index
         
         if isempty(obj.pars.CameraSourceVar)
            if isstruct(obj.pars.CameraKey)
               source = obj.pars.CameraKey.Source;
               signalIndex = obj.pars.CameraKey.Index;
            else
               source = [];
               signalIndex = nan;
            end
            return;
         end
         source = meta.(obj.pars.CameraSourceVar);
         camKeyIndex = find(ismember({obj.pars.CameraKey.Source},source),1,'first');
         signalIndex = obj.pars.CameraKey(camKeyIndex).Index;
      end
      
      % Set parameters struct
      function obj = setPars(obj,params,updateParsing)
         % SETPARS  Set parameters (nigeLab.defaults.Video() output)
         %
         %  obj.setPars(params);
         %  obj.setPars(params,updateParsing);
         %
         %  By default, updateParsing is true.
         
         if nargin < 3
            updateParsing = true;
         end
         obj.pars = params;
         obj.isConfigured = params.HasVideo;
         if ~obj.isConfigured
            return;
         end
         if updateParsing
            obj = obj.parseMetaData;
         end
      end
   end
   
   methods (Access = private)      
      % Parse metadata from name
      function obj = parseMetaData(obj)
         % PARSEMETADATA  Parse name metadata using DynamicVars parameter
         
         name_data = strsplit(obj.F.name,obj.pars.Delimiter);
         if numel(name_data) ~= numel(obj.pars.DynamicVars)
            error(['Mismatch between number of parsed name elements (%g)' ...
                   ' and number of cell elements in DynamicVars (%g)'],...
               numel(name_data),numel(obj.pars.DynamicVars));
         end
         obj.meta = struct;
         for i = 1:numel(name_data)
            if strcmp(obj.pars.DynamicVars{i}(1),obj.pars.IncludeChar)
               obj.meta.(obj.pars.DynamicVars{i}(2:end)) = name_data{i};
            end
         end
      end
      
      % Set video-related info properties
      function obj = setVideoInfo(obj,propName,propVal)
         % SETVIDEOINFO  Sets the properties related to video info
         %
         %  obj.SETVIDEOINFO; % Set all properties
         %  obj.SETVIDEOINFO('propName',propVal); % Set a specific
         %                                        % property/value pair
         
         if nargin < 3
            V = getVideoReader(obj);
            obj.Name = V.Name;
            obj.Duration = V.Duration;
            obj.FS = V.FrameRate;
            obj.Height = V.Height;
            obj.Width = V.Width;
            obj.NFrames = V.NumberOfFrames;
            obj.Source = getVideoSourceInfo(obj);
            clear('V');
         else
            obj.(propName) = propVal;
         end
      end
   end
   
   
end