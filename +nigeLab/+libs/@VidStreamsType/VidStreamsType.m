classdef VidStreamsType < handle
   % VIDSTREAMSTYPE  Handle class for managing blockObj.Streams.VidStreams
   
   properties (GetAccess = public, SetAccess = private)
      at  % Struct 
%       --> info  % 'nigeLab.utils.signal' class object
%       --> data  % Empty on init. Becomes a matfile when Stream is linked
%       --> t     % Times corresponding to video frames

      v     % nigeLab.libs.VideosFieldType class object: handles Video
      fname % Filename
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
            'data',cell(numel(vidStreamSignals),1),...
            't',cell(numel(vidStreamSignals),1));
         for iA = 1:numel(obj.at)
            obj.at(iA).info = vidStreamSignals(iA);
            obj.at(iA).t = videosFieldObj(iA).getFrameTimes;
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
         
         switch field
            case {'Video', 'Videos'}
               [filename,fileIsPresent] = obj.v.getFile;
            case 'VidStreams'
               [filename,fileIsPresent] = obj.checkData;
            otherwise
               error('Unexpected ''field'' value: %s',field);
         end
      end
      
      % Returns name string to use in file name
      function str = getNameStr(obj,iVid)
         % GETNAMESTR  Parse naming in a consistent format
         
         str = sprintf('%s-%s-%s',...
            obj.at(iVid).info.Source,...
            obj.at(iVid).info.Name,...
            obj.at(iVid).info.Group);
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
               obj.at(i).data = nigeLab.utils.makeDiskFile(diskPars);
            else
               fileIsPresent(i) = true;
               obj.at(i).data = nigeLab.libs.DiskData('Hybrid',fName);
            end
         end
      end
   end
   
end