classdef nigelObj < matlab.mixin.Copyable
% NIGELOBJ    Superclass for storage objects in nigeLab.
%
%     --  WIP  --  (2019-12-13)
%
%  NIGELOBJ Properties:
%     FieldType - Categorizes each 'Fields' element as one of the following
%        * 'Channels'  --  Fields belong to each Recording Channel
%        * 'Streams'  --  Data is streamed independently of recording chans
%        * 'Events'  --  Parsed events independent of recording channels
%        * 'Videos'  --  Array of objects for associated videos
%        * 'Meta'  --  Metadata about the recording, such as Header info
%
%     Fields - Specific elements, such as 'Raw Data' (Raw) to be collected
%
%     Pars - Parameters struct
%
%     Status - Processing "progress" of each Fields (true: completed)
%
%     UserData - Property to store user-defined data
%
%  NIGELOBJ Methods:
%     nigelObj - Class constructor
%
%     Empty - Create an Empty NIGELOBJ object or array
   
   %% PROPERTIES
   % PUBLIC
   % VISIBLE
   % SETOBSERVABLE
   properties (Access = public, SetObservable = true)
      Name        char        % Name of the nigelObj
      Status      logical     % Stores status of a given processing step
   end
   
   % PUBLIC
   % VISIBLE
   properties (Access = public)
      Meta        struct      % Metadata struct
      Pars        struct      % Parameters struct
      UserData                % Allow UserData property to exist
   end
   
   % PUBLIC
   % HIDDEN
   properties (Access = public, Hidden = true)      
      % Flags
      IsEmpty = true   % True if no data in this (e.g. Empty() method used)
   end
   
   % PRIVATE
   properties (Access = private)
      ViableFieldTypes = {'Channels','Events','Meta','Streams','Videos'}
   end
   
   %% METHODS
   % PUBLIC
   methods (Access = public, Static = false)
      % nigelObj class constructor
      function obj = nigelObj()
         % To add in future
      end
      
      % Overload to 'isempty' 
      function tf = isempty(obj)
         % ISEMPTY  Returns true if .IsEmpty is true or if builtin isempty
         %          returns true. If obj is array, then returns an
         %          array of true or false for each element of obj.
         %
         %  tf = isempty(nigelObj);
         
         if numel(obj) == 0
            tf = true;
            return;
         end
         
         if ~isscalar(obj)
            tf = false(size(obj));
            for i = 1:numel(obj)
               tf(i) = isempty(obj(i));
            end
            return;
         end
         
         tf = obj.IsEmpty || builtin('isempty',obj);
      end
   end
   
   % PUBLIC
   % STATIC
   methods (Access = public, Static = true)
      % Method to instantiate "Empty" nigelObjects from constructor
      function obj = Empty(n)
         % EMPTY  Creates "empty" block or block array
         %
         %  obj = nigeLab.nigelObj.Empty();  % Makes a scalar
         %  obj = nigeLab.nigelObj.Empty(n); % Make n-element array Block
         
         if nargin < 1
            n = [1, 1];
         else
            n = nanmax(n,1);
            if isscalar(n)
               n = [1, n];
            end
         end
         
         obj = nigeLab.nigelObj(n);
      end
   end
   
end