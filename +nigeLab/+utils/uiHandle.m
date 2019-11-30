classdef uiHandle < handle
   % UIHANDLE  Handle class to store data for simple selector UI
   %
   %  obj = nigeLab.utils.uiHandle('prop1',prop1val,....)
   
   properties (GetAccess = public, SetAccess = private)
      data = struct; % Data is a struct with dynamic field assignment
   end
   
   methods (Access = public)
      function obj = uiHandle(varargin)
         % UIHANDLE  Handle class to store data for simple selector UI
         %
         %  obj = nigeLab.utils.uiHandle('prop1',prop1val,....)
         
         obj.set(varargin);
         
      end
   end
   
   methods (Access = public)
      function disp(obj)
         if numel(obj) > 1
            for i = 1:numel(obj)
               disp(obj(i));
            end
            return;
         end
         out = get(obj);
         disp(out);
      end
      
      function varargout = get(obj,varargin)
         % GET Get 'name', value properties from fields of data
         
         if nargin < 2
            varargin = fieldnames(obj.data);
         else
            if nargout ~= (numel(varargin))
               error('Invalid output assignment (requested %g args but assigned %g args).',...
                  numel(varargin),nargout);
            else
               varargout = cell(size(varargin));
            end
         end
         
         if nargin < 2
            varargout = {struct};
            for i = 1:numel(varargin)
               varargout{1}.(varargin{i}) = obj.data.(varargin{i});
            end
            return;
         else
            for i = 1:numel(varargin)
               if isfield(obj.data,varargin{i})
                  varargout{i} = obj.data.(varargin{i});
               else
                  warning('%s is not a valid data field.',varargin{i});
                  varargout{i} = [];
               end
            end
            return;
         end
      end
      
      function set(obj,varargin)
         % SET  Set 'name', value properties for data
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               obj(i).set(varargin);
            end
            return;
         end
         % If it was passed for handling array case
         if numel(varargin) == 1
            varargin = varargin{1};
         end
         
         for i = 1:2:numel(varargin)
            obj.data.(varargin{i}) = varargin{i+1};
         end
      end
   end
end