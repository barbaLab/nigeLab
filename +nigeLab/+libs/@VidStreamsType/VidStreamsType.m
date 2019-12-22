classdef VidStreamsType < handle
   % VIDSTREAMSTYPE  Handle class for managing blockObj.Streams.VidStreams
   %
   % VIDSTREAMSTYPE Methods:
   % VidStreamsType - Class constructor
   %
   % GetStream - Returns the SubStream corresponding to 'streamName'
   %     Note that 'substreams' are slightly different than 'vidstream' and
   %     can be thought of as a more general 'stream' type (e.g. the core
   %     data content of both 'VidStreams' and 'Streams' end up being the
   %     same in 'SubStreams').
   % 
   % VIDSTREAMSTYPE Properties:
   % at - (Private) struct that contains the stream data
   %     --> This should be referenced using `GetStream` method <--
   %
   % Block - (Private) handle referencing the associated recording Block

   
   properties (GetAccess = private, SetAccess = private)
      at  % Struct with fields 'info', 'data', 't', and 'fs'
%       --> info  % 'nigeLab.utils.signal' class object
%       --> diskdata  % Empty on init. Becomes a matfile when linked
%       --> tag     % Tag for quick reference of a given vidStream
%       --> t     % Times corresponding to video frames
%       --> fs    % Sample rate
      
      Video nigeLab.libs.VideosFieldType % References the "parent" video
   end

   % PUBLIC
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

         obj.Video = videosFieldObj;
         % '.at' is the actual reference to the streams
         obj.at = nigeLab.utils.initChannelStruct('VidStreams',...
                     numel(vidStreamSignals));
         for iA = 1:numel(obj.at)
            obj.at(iA).info = vidStreamSignals(iA);
            obj.at(iA).t = videosFieldObj.getFrameTimes;
            obj.at(iA).tag = obj.getNameStr(iA);
            obj.at(iA).fs = videosFieldObj.FS;
         end
                 
      end
   end
   
   % PUBLIC
   % Currently just 'getStream'
   methods (Access = public)    
      % Method to find the index of the corresponding stream
      function idx = findIndex(obj,argMatch,matchType)
         % FINDINDEX  Returns an index of the corresponding stream
         %
         %  idx = obj.findIndex(argMatch,matchType)
         %
         %  If obj is given as an array input, then output is index to
         %  match the corresponding signal argument and type. argMatch and
         %  matchType may be specified as cell arrays, in which case the
         %  matching signal must match each element-wise combination.
         
         if numel(obj) > 1
            idx = nan(size(obj));
            for i = 1:numel(obj)
               tmp = obj(i).findIndex(argMatch,matchType);
               if ~isempty(tmp)
                  idx(i) = tmp;
               end
            end
            return;
         end
         
         if ~iscell(argMatch)
            argMatch = {argMatch};
         end
         if ~iscell(matchType)
            matchType = {matchType};
         end
         
         tf = true(size(obj.at));
         for i = 1:numel(argMatch)
            tf = tf & belongsTo(obj.at.info,argMatch{i},matchType{i});
         end
         idx = find(tf,1,'first');
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
            stream = nigeLab.utils.initChannelStruct('SubStreams',0);
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
         
         idx = obj.belongsTo(obj.at.info,streamName,'Name') & ...
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
      
   end
   
   % PRIVATE
   % "GET" methods
   methods (Access = private)  
      % Check to see if data is present and if not, initialize the stream
      function [filename,fileIsPresent] = checkData(obj)
         % CHECKDATA    Check if data is present, if not, make file
         %
         %  [filename, fileIsPresent] = obj.checkData();
         
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
      
      % Returns name string to use in file name
      function str = getNameStr(obj,iStream)
         % GETNAMESTR  Parse naming in a consistent format
         %
         %  str = obj.getNameStr; Returns name as %s-%s-%s formatted char
         %                        --> One cell element for each VidStream
         %                             if there are multiple per video.
         %
         %  str = obj.getNameStr(iStream); Returns name as char array
         %                                (%s-%s-%s formatted)
         
         if nargin < 2
            str = cell(numel(obj.at),1);
            for i = 1:numel(str)
               str{i} = getNameStr(obj,i);
            end
            return;
         end
         
         str = sprintf('%s-%s-%s',...
            obj.at(iStream).info.Source,...
            obj.at(iStream).info.Name,...
            obj.at(iStream).info.Group);
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
   
end