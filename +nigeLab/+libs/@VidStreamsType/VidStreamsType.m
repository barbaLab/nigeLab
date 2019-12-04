classdef VidStreamsType < handle
   % VIDSTREAMSTYPE  Handle class for managing blockObj.Streams.VidStreams
   
   properties (GetAccess = public, SetAccess = private)
      at  % Struct with fields 'info', 'data', 't', and 'fs'
%       --> info  % 'nigeLab.utils.signal' class object
%       --> diskdata  % Empty on init. Becomes a matfile when linked
%       --> t     % Times corresponding to video frames
%       --> fs    % Sample rate

      v     % nigeLab.libs.VideosFieldType class object: handles Video
      fname % Filename for this VIDEO
   end

   % CONSTRUCTOR
   methods (Access = public)
      % Class constructor
      function obj = VidStreamsType(videosFieldObj,vidStreamSignals)
         % VIDSTREAMSTYPE Constructor for object to manage VidStreams
         %
         %  obj = ...
         %   nigeLab.libs.VidStreamsType(videosFieldObj,vidStreamSignals);
         %
         %  inputs:
         %  videosFieldObj -- nigeLab.libs.VideosFieldType class object
         %                       + if provided as an array, then
         %                         obj is returned as an array where each
         %                         array element has a 1:1 correspondence
         %                         with an element of videosFieldObj
         %                         represented as the 'obj.v' property.
         %
         %  vidStreamSignals -- nigeLab.utils.signal class object (scalar
         %                          or array). This value is set as the
         %                          'obj.at' property for each element of
         %                          the returned obj array. For example, if
         %                          vidStreamSignals is an array, and
         %                          videosFieldObj is an array, then it
         %                          means each returned element of obj
         %                          corresponds to a video with all the
         %                          streams in vidStreamSignals.
         
         % Empty object initialization
         if isnumeric(videosFieldObj) 
            dims = videosFieldObj;
            if numel(dims) < 2
               dims = [dims, 1];
            end
            obj = repmat(obj,dims);
            return;
         end
         
         % Handle input arrays
         if numel(videosFieldObj) > 1
            obj = VidStreamsType(numel(videosFieldObj));
            for i = 1:numel(videosFieldObj)
               % All vidStreamSignals associated with each video
               obj(i) = VidStreamsType(videosFieldObj(i),vidStreamSignals);
            end
            return;
         end
         
         % Set the 'v' property, which is a wrapper for interacting with
         % the actual Video file
         obj.v = videosFieldObj;
         obj.at = struct('info',cell(numel(vidStreamSignals),1),...
            'diskdata',cell(numel(vidStreamSignals),1),...
            't',cell(numel(vidStreamSignals),1),...
            'fs',cell(numel(vidStreamSignals),1));
         for iA = 1:numel(obj.at)
            obj.at(iA).info = vidStreamSignals(iA);
            obj.at(iA).t = videosFieldObj(iA).getFrameTimes;
            obj.at(iA).fs = obj.v.FS;
         end
                 
      end
   end
   
   % "GET" and "SET" methods
   methods (Access = public)
      % Get filename of video using UNC path
      function [filename,fileIsPresent] = getFile(obj,field)
         % GETFILE  Returns filename using UNC path convention
         
         if numel(obj) > 1
            [filename,fileIsPresent] = nigeLab.utils.initCellArray(1,numel(obj));
            for i = 1:numel(obj)
               [filename{i},fileIsPresent{i}] = obj(i).getFile(field);
            end
            fileIsPresent = cellfun(@all,fileIsPresent,'UniformOutput',true);
            fileIsPresent = reshape(fileIsPresent,1,numel(fileIsPresent));
            return;
         end
         
         switch lower(field)
            case {'video', 'videos'}
               [filename,fileIsPresent] = obj.v.getFile;
            case {'vidstreams','vidstream'}
               [filename,fileIsPresent] = obj.checkData;
            otherwise
               error('Unexpected ''field'' value: %s',field);
         end
      end
      
      % Returns the 'name' field for all elements of 'field' and also the
      % indexing as a 2-column vector where the first column indexes Videos
      % elements and second indexes either (.at) or (.v) elements.
      function [name,idx] = getName(obj,field)
         % GETNAME  Returns name and 2-column indexing vector for streams
         %
         % [name,idx] = obj.getName('video');      Returns video names
         % [name,idx] = obj.getName('vidstreams'); Returns stream names
         %
         % Rows of idx correspond to elements of name. The first column of
         % idx represents indexing into the obj (blockObj.Videos) array,
         % while the second column represents indexing into the '.v' or
         % '.at' streams for 'video' and 'vidstreams' respectively.
         
         if numel(obj) > 1
            [name,idx] = nigeLab.utils.initCellArray(numel(obj),1);
            for i = 1:numel(obj)
               [name{i},idx{i}] = obj(i).getName(field);
            end
            return;
         end
         
         switch lower(field)
            case {'video','videos'}
               [name,idx] = obj.getVidName;
            case {'vidstreams','vidstream'}
               [name,idx] = obj.getVidStreamName;
            otherwise
               error('Unrecognized fieldtype: %s',field);
         end
      end
      
      % Returns name string to use in file name
      function str = getNameStr(obj,iVid)
         % GETNAMESTR  Parse naming in a consistent format
         %
         %  str = obj.getNameStr; Returns name as %s-%s-%s formatted char
         %                        --> One cell element for each VidStream
         %                             if there are multiple per video.
         %
         %  str = obj.getNameStr(iVid); Returns name as char array
         %                                (%s-%s-%s formatted)
         
         
         if nargin < 2
            str = cell(numel(obj.at),1);
            for i = 1:numel(str)
               str{i} = getNameStr(obj,i);
            end
            return;
         end
         
         str = sprintf('%s-%s-%s',...
            obj.at(iVid).info.Source,...
            obj.at(iVid).info.Name,...
            obj.at(iVid).info.Group);
      end
      
      % Returns the VidStream corresponding to streamName
      function stream = getStream(obj,streamName,source,scaleOpts,stream)
         % GETSTREAM  Return a struct with the fields 'name', 'data' and
         %              'fs' that corresponds to the video stream named
         %              'streamName'. If obj is an array, then 'data' is
         %              concatenated by info.Source so that a single 'data'
         %              field represents the full recording session (if
         %              there are multiple videos from same Source).
         %
         %  stream = obj.getStream(streamName,source);
         %
         %  streamName  --  Name of stream
         %  source  --  Signal "source" (camera angle)
         %  scaleOpts  --  Struct with scaling options for stream
         %  stream  --  Typically not specified; provided by recursive
         %                 method call so that streams can be concatenated
         %                 together.  
         
         if nargin < 5
            stream = nigeLab.utils.initChannelStruct('substreams',1);
         end
         
         if nargin < 4
            scaleOpts = nigeLab.utils.initScaleOpts();
         end
         
         if nargin < 3
            error('Must provide 3 input arguments.');
         end
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               stream = obj(i).getStream(streamName,source,scaleOpts,stream);
            end
            if isempty(stream.data)
               stream = [];
            end
            return;
         end
         
         idx = belongsTo(obj.at.info,streamName,'Name') & ...
               belongsTo(obj.at.info,source,'Source');
         if sum(idx) < 1
            return;
         else
            idx = find(idx,1,'first');
         end
         % Return stream in standardized "substream" format
         stream.name = streamName;
         if isempty(obj.at(idx).diskdata)
            return;
         end
         stream.data = [stream.data, obj.at(idx).diskdata.data];
         stream.fs = obj.at(idx).fs;
         stream.t = (0:(numel(stream.data)-1))/stream.fs;
         stream.data = nigeLab.utils.applyScaleOpts(stream.data,scaleOpts);
      end
      
      % Set the UNC Path for this object
      function setPath(obj,uncPath,idx)
         % SETPATH  Set UNC path (filename) for associated files
         
         if nargin < 3
            idx = 1;
         end
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               obj(i).setPath(uncPath,i);
            end
            return;
         end
         obj.fname = cell(numel(obj.at),1);
         if isfield(obj.v.meta,obj.v.pars.MovieIndexVar)
            idx = str2double(obj.v.meta.(obj.v.pars.MovieIndexVar));
         end
         
         for i = 1:numel(obj.at)
            obj.fname{i} = fullfile(sprintf(strrep(uncPath,'\','/'),...
               obj.getNameStr(i),idx,'mat'));
         end
      end
      
   end
   
   % Private "GET" methods
   methods (Access = private)
      % Return video file NAME (without extension)
      function [name,idx] = getVidName(obj,idx)
         % GETVIDNAME  Returns video file NAME (without extension)
         %
         %  name = obj.getVidName;  Name is a char array if only one
         %                          element in obj, otherwise it is a cell
         %                          array where each is a char array
         %                          corresponding to an element of obj.
         
         if nargin < 2
            idx = [1,1];
         end
         
         if numel(obj) > 1
            name = cell(size(obj));
            idx = repmat((1:numel(obj)).',1,2);
            for i = 1:size(idx,1)
               name{i} = obj(idx(i,1)).getVidName(idx(i,:));
            end
            return;
         end
         
         [~,name,~] = fileparts(obj.v.Name);
      end
      
      % Return video stream NAME
      function [name,idx] = getVidStreamName(obj,idx)
         % GETVIDSTREAMNAME  Returns video stream NAME from signal info
         %
         %  name = obj.getVidStreamName;  
         %  name = obj.getVidStreamName(idx); --> idx is for Videos index
         %     
         %  --> name is a char array if only one element in obj, otherwise
         %      it is a cell array where each is a char array corresponding
         %      to an element of obj.
         
         if nargin < 2
            idx = (1:numel(obj)).';
         end
         
         if numel(obj) > 1
            [name,idx_tmp] = nigeLab.utils.initCellArray(numel(obj),1);
            for i = 1:length(idx)
               [name{i},idx_tmp{i}] = obj(idx(i,1)).getVidStreamName(idx(i,1));
            end
            idx = idx_tmp;
            return;
         end
         
         if numel(obj.at) > 1
            name = cell(size(obj.at));
            idx_tmp = nan(numel(name),2);
            for i = 1:numel(obj.at)
               [name{i},idx_tmp(i,:)] = obj.getVidStreamName([idx,i]);
            end
            idx = idx_tmp;
            return;
         else
            name = obj.at.info.Name;
            idx = [idx, 1];
         end
         
         name = obj.at(idx(1,2)).info.Name;
      end
   end
   
   methods (Access = private)
      function [filename,fileIsPresent] = checkData(obj)
         % CHECKDATA    Check if data is present, if not, make file
         
         filename = cell(1,numel(obj.at));
         fileIsPresent = false(1,numel(obj.at));
         
         
         for i = 1:numel(obj.at)
            fName = nigeLab.utils.getUNCPath(obj.fname{i});
            if isempty(fName)
               error('Filenames not yet set using obj.setPath.');
            end
            
            if exist(fName,'file')==0
               diskPars = struct('format','Hybrid',...
                  'name',fName,...
                  'size',size(obj.at(i).t),...
                  'access','w',...
                  'class','single');
               obj.at(i).diskdata = nigeLab.utils.makeDiskFile(diskPars);
            else
               fileIsPresent(i) = true;
               obj.at(i).diskdata = nigeLab.libs.DiskData('Hybrid',fName);
            end
            filename{i} = fName;
         end
      end
   end
   
end