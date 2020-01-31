classdef DiskData < handle & ...
                    matlab.mixin.SetGet & ...
                    matlab.mixin.CustomDisplay
   %DISKDATA   Class to efficiently handle data without loading to RAM
   %
   %  D = DiskData(Datatype_,DataPath)
   %  D = DiskData(Datatype_,DataPath,Data)
   %  D = DiskData(___,'name',value,...)
   %
   %  --------
   %   INPUTS
   %  --------
   %  Datatype_   :     If 2 arguments are specified, the first argument
   %                       becomes Datatype_, which is either 'MatFile' or
   %                       'Hybrid' currently (string). This must be specified
   %                       in conjunction with DataPath (below).
   %
   %  DataPath    :     (String) full filename of data file being pointed to
   %                       by the DiskData class.
   %
   %    ---
   %
   %   Data       :     Data to be associated with the DiskData object. This
   %                       will automatically write the contents of Data to
   %                       that file.
   %
   %    ---
   %
   %  varargin    :     (Optional) 'name', value input argument pairs:
   %                       -> 'name'
   %                       -> 'size'
   %                       -> 'class'
   %                       -> 'access' : 'r' (default, read-only) or 'w'
   %                                     'w' (for write access)
   %
   %  DISKDATA Properties:
   %     diskfile_ - Contains actual 'MatFile'
   %     type_ - 'MatFile' (only MatFile) or 'Hybrid' (combo H5 stuff)
   %     name_ - Name of variable pointed to by DiskData array
   %     size_ - Size (dimensions) of DiskData array
   %     bytes_ - Number of bytes in DiskData
   %     class_ - Class of data pointed to by DiskData array
   %     chunks_ - Size of "chunks" to read
   %     access_ - Whether access is read-only (default) or writable
   %     writable_ - Whether file is writable (parsed from access_)
   %
   %  DISKDATA Methods:
   %     DiskData - Class constructor
   
   % % % PROPERTIES % % % % % % % % % %
   % DEPENDENT,TRANSIENT,PUBLIC
   properties (Dependent,Transient,Access=public)
      Animal      char     % (char) name of animal used in recording
      Block       char     % (char) name of recording Block
      Complete    logical  % (logical) Is data in the file "Complete"? (e.g. not just initialized data)
      Empty       logical  % (logical) Is there data in the file at all? 
      File        char     % (char) Name of file pointed to by obj.diskfile_
      Index       double   % (double) Current index (sample) in this dataset; defaults to 1, useful for tracking appending
      Locked      logical  % (logical) Is the file Read-Only (true) or Write-Access (false)?
      Tank        char     % (char) name of animal "grouping"
      type                 % Event type [must be 0, 1, or 2]; not the same as .type_, which refers to diskfile_
      value                % Value associated with event (e.g. spike cluster class)
      tag                  % Tag associated with event (e.g. spike cluster label)
      ts                   % Time of event (seconds)
      snippet              % Values around the event
      data                 % Values stored in 'Hybrid' and 'MatFile' format
   end
   
   % DEPENDENT,HIDDEN,TRANSIENT,PUBLIC
   properties (Dependent,Hidden,Transient,Access=public)
      chunks_h5      double      % (numeric) Chunking dimensions for h5
      class_h5       char        % (char) H5 constant for .class_
      const_dim_ext  double      % (numeric) Extent of dimension to remain constant
      const_dim_idx  double      % (numeric) Index of dimension to remain constant
      dims_h5        double      % (numeric) Dimensions (.size_ for h5)
      maxdims_h5     double      % (numeric) Max. dims (depend on .type_)
      rank_h5   (1,1)double = 1  % (scalar double) H5 rank of memory space
      var_dim_idx    double      % (numeric) "Variable" dimension index (the one that extends)
   end
   
   % PROTECTED
   properties (Access=protected)
      compress_   (1,1) double  = 1         % Value between 0 and 9, where 9 is the highest compression
      diskfile_         char    = ''        % Char array pointer to actual diskfile
      type_             char    = 'MatFile' % 'MatFile' (only MatFile) or 'Hybrid' (combo H5 stuff) or 'Event' (spikes etc)
      name_             char    = 'data'  % Name of variable pointed to by DiskData array (default: 'data')
      size_             double            % Size (dimensions) of DiskData array
      bytes_            double            % Number of bytes in DiskData
      class_            char    = 'double'% Class of data pointed to by DiskData array
      chunks_           double  = [1 2048]% Size of "chunks" to read
      access_     (1,1) char    = 'r'     % Access type (default: 'r')
      writable_         logical           % Whether file is writable
      overwrite_  (1,1) logical = false   % By default, constructor does not overwrite if data is already present
      verbose_    (1,1) logical = true    % Set false to suppress `getAttr` and `setAttr` print commands (maybe)
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % PUBLIC (constructor & overloads)
   methods (Access=public)
      % Class constructor
      function obj = DiskData(varargin)
         %DISKDATA   Constructor for nigeLab.libs.DiskData file storage
         %
         %  D = DiskData(Datatype_,DataPath)
         %  D = DiskData(Datatype_,DataPath,Data)
         %
         %  --------
         %   INPUTS
         %  --------
         %  Datatype_   :     If 2 arguments are specified, the first
         %                       argument becomes Datatype_, which is
         %                       either 'MatFile', 'Hybrid', or 'Event' 
         %                       (char array). This must be specified in
         %                       conjunction with DataPath (below).
         %
         %  DataPath    :     (String) full filename of data file being
         %                       pointed to by the DiskData class.
         %
         %    ---
         %
         %   Data       :     Data to be associated with the DiskData
         %                       object. This will automatically write the
         %                       contents of Data to that file.

         %PARSE INPUTS
         keyProps=...
            {'name','size','class','access','verbose',...
             'overwrite','chunks','writable','compress'};
         nargin=numel(varargin);
         
         % Get the index where to start parsing "variable" part of varargin
         jj=nargin+1;
         for ii=1:nargin
            if ~isempty(find(strcmp(varargin(ii),keyProps),1))
               jj=ii;
               break;
            end
         end
         % "Non-variable" elements indicate the total number of "default"
         % input arguments. Parse object properties from those elements.
         nargin=jj-1;
         
         %PARSE VARARGIN
         % "Variable" part of varargin allows setting of "non-default"
         % input arguments.
         mc = metaclass(obj);
         p = {mc.PropertyList.Name};
         for iV = jj:2:numel(varargin)
            propName = varargin{iV};
            if ~strcmp(propName(end),'_')
               propName = [lower(propName) '_']; 
            end
            if ismember(propName,p)
               obj.(propName) = varargin{iV+1};
            end
         end
         obj.writable_ = strcmpi(obj.access_,'w');
         
         % Depending on number of inputs, varargin means different things
         switch nargin
            case 1 % Only 1 "default" input provided 
               % This case is specifically for dealing with MatFiles.
               obj.initMatFile(varargin{1});
            case 2 % 2 "default" inputs provided: file type and file name
               switch lower(varargin{1}) % First arg is the file type
                  case 'matfile' % Can deal with MatFiles
                     obj.type_ = 'MatFile'; % Formatting
                     obj.initMatFile(varargin{2}); % Second arg is fName
                  case 'hybrid' % Deals with both MatFile and HDF5
                     obj.type_ = 'Hybrid'; % Formatting
                     obj.initHybridFile(varargin{2}); % Second arg is fName
                  case {'event','events'} % Deal with Spikes and other Events
                     obj.type_ = 'Event';
                     obj.initEventFile(varargin{2}); % Second arg is fName
                  otherwise % Throw error (bad file type)
                     error(['nigeLab:' mfilename ':BadType'],...
                        '[DISKDATA]: Unknown data format'); 
               end
            case 3 %(All) 3 "default" inputs: data was included as well               
               % Since the DiskData object was provided with data in the
               % constructor, then it must be writable; however, do not use
               % `unlockData` because if the file exists and we didn't
               % explicitly specify to overwrite in the constructor,
               % setting these properties manually gives us a chance to
               % throw an error and not overwrite by accident
               obj.writable_ = true;
               obj.access_ = 'w';
               
               % Second arg is fName, third arg is data
               obj.saveFile(varargin{2},varargin{3},varargin{1}); 
            otherwise % Throw error (wrong # inputs)
               error(['nigeLab:' mfilename ':BadNumInput'],...
                  '[DISKDATA]: Wrong number of input parameters');
         end
         
         % Set the "Index" attribute
         if isempty(obj.Index)
            obj.Index = 1;
         end
         
         if isempty(obj.Locked) % if "Locked" attribute not set
            % "unlock" or "lock" according to .writable_ status
            if obj.writable_
               unlockData(obj);
            else
               lockData(obj);
            end
         end
      end
      
      data = subsref(obj,S)  % Overloaded subscript reference method
      obj  = subsasgn(obj,S,data)     % Overloaded subscript assignment method
      
      % Overloaded method to return the absolute value of data in diskfile_
      function Out = abs(obj)
         %ABS   Overloaded function for getting absolute value of DiskData
         %
         %  Out = abs(obj);
         %  --> Returns absolute value by directly reading entire file
         
         varname=[ '/' obj.name_];
         a = h5read(obj.getPath,varname,[1 1],[1 inf]);
         Out = abs(a);
      end
      
      % Method for appending data to DiskData file
      function out = append(obj,data,dim)
         %APPEND   Overloaded function for adding data to DiskData file
         %
         %  append(obj,b,dim);
         %  
         %  obj : nigeLab.libs.DiskData object
         %  data : Data to append
         %  dim : (optional) dimension along which to append data
         %
         %  out = append(obj,obj_to_append,dim);
         %  --> Can provide 2nd arg (data) as obj_to_append, another
         %  nigeLab.libs.DiskData, in order to form an array of DiskData
         %  objects.
         
         % If it is MatFile, cannot extend along any dimensions
         if strcmp(obj.type_,'MatFile')
            nigeLab.libs.DiskData.throwImproperAssignmentError('MatFile');
            out = [];
            return;
         end
         
         % Check that DiskData object can be modified at all
         if ~obj.writable_
            % This one causes actual Matlab error
            nigeLab.libs.DiskData.throwImproperAssignmentError('standard');
         end
         varname_ = ['/' obj.name_];
         
         % Validate the data class against DiskData class_ property
         if ~strcmp(obj.class_,class(data))
            nigeLab.libs.DiskData.throwImproperAssignmentError('class',...
               obj.class_,class(data));
            out = [];
            return;
         end
         
         % If data (to append) is empty, don't do anything
         if isempty(data)
            out = [];
            return;
         end
         
         % By default, append along first "compatible" dimension
         if nargin < 3
            dim = obj.var_dim_idx; % Depends only on obj.type_            
         end
         
         % Validate that appending dimension is fine
         if dim < 1
            error(['nigeLab:' mfilename ':InvalidDim'],...
               '[DISKDATA]: Append dimension (`dim`) must be >= 1');
         elseif dim > obj.rank_h5
            error(['nigeLab:' mfilename ':InvalidDim'],...
               ['[DISKDATA]: Append dimension (`dim`: %g) exceeds ' ...
               'data dimension (%g)\n'],dim,obj.rank_h5);
         end
         start_offset = zeros(1,obj.rank_h5);
         start_offset(dim) = 1;
         
         % Set arguments to h5write
         start = obj.size_ + start_offset;
         count = ones(1,obj.rank_h5);
         stride = ones(1,obj.rank_h5);
         block = size(data);
         block(~logical(start_offset)) = 0;
         start(~logical(start_offset)) = 1;
         obj.size_= obj.size_ + block; 
         
         % Get file, data, and space identifiers
         h5write(obj.diskfile_,varname_,data,start,size(data),stride);

         % Update file size
         obj.bytes_ = obj.getFileSize();     
         
         % If requested, provide output
         if nargout > 0
            out = h5read(obj.diskfile_,varname_,...
               ones(1,obj.rank_h5),[inf,inf],ones(1,obj.rank_h5));
         end
      end
      
      % Overloaded method for returning class of object contents
      function cl = class(obj)
         %CLASS  Overloaded function for getting DiskData array class
         %
         %  cl = class(obj);
         %  --> Returns class as `'DiskData.[class]'` as assigned to the
         %      property obj.class_
         
         cl = sprintf('DiskData.%s', obj.class_);
      end
      
      % Overloaded method to cast the contents of diskfile_ to double
      function Out = double(obj)
         %DOUBLE Overloaded function for casting DiskData array to double
         %
         %  Out = double(obj);
         %  --> Returns value directly from file cast as `'double'` type
         
         varname=[ '/' obj.name_];
         a = h5read(obj.getPath,varname,[1 1],[1 inf]);
         Out= double(a);
      end
      
      % Overloaded method to index the end of the diskfile_ contents
      function ind = end(obj,k,n)
         %END   Overloaded function for indexing end of DiskData array
         %
         %  Ensure that 'end' indexing keyword always points to the actual
         %  "end" dimension of the data
         
         szd = size(obj);
         if k < n
            ind = szd(k);
         else
            ind = prod(szd(k:end));
         end
      end
      
      % Overloaded method to prevent concatenation of nigeLab.libs.DiskData
      function C = horzcat(varargin)
         %HORZCAT  Overloaded method to prevent concatenation
         %
         %  C = horzcat(obj1,obj2,...);
         %
         %  C = [obj1,obj2,...];
         
         nigeLab.utils.cprintf('Comments',...
            '[DISKDATA]: Cannot concatenate DiskData objects\n');
         C = varargin{1}; % Simply returns the first element of the array
      end
      
      % Overloaded method to indicate if the object or its file are empty
      function b = isempty(obj)
         %ISEMPTY  Overloaded function for checking if DiskData has data
         %
         %  b = isempty(obj);
         %  --> Returns TRUE if nigeLab.libs.DiskData object is empty
         %  --> Returns TRUE if all values returned by size(obj) are zero
         
         if ~builtin('isempty',obj)
            b = all(size(obj)==0);
         else
            b = true;
         end
      end
      
      % Overloaded method to return the maximum size of saved variable
      function l = length(obj)
         %LENGTH  Overloaded function for getting DiskData array length
         %
         %  l = length(obj);
         %  --> Returns a scalar integer value that is the maximum length
         %        of any element of the .size field returned from the call
         %        whos(obj.diskfile_), which is the matfile associated with
         %        a DiskData object.
         %        * If multiple variables are stored, this returns the
         %          largest dimension from any of the stored variables.
         
         l = max(obj.size_);
      end

      % Overloaded elementwise subtraction method
      function Out = minus(obj,b)
         %MINUS    Overloaded function for subtraction on DiskData array
         %
         %  Out = obj - b;
         %  --> obj : nigeLab.libs.DiskData object
         %  --> b   : Can be:
         %        --> nigeLab.libs.DiskData object
         %        --> numeric array of same size as
         %              obj.diskfile_.(obj.name_)
         %
         %  If inputs are given correctly, returned output does NOT write
         %  to a disk file, but instead simply returns the result of the
         %  subtraction operation to the caller workspace.
         
         varname=[ '/' obj.name_];
         a = h5read(obj.getPath,varname,[1 1],[1 inf]);
         if isa(b,'nigeLab.libs.DiskData')
            varname=[ '/' b.name_];
            b = h5read(b.getPath,varname,[1 1],[1 inf]);
            Out=a-b;
         elseif isnumeric(b)
            Out=a-b;
         end
      end
      
      % Overloaded matrix multiplication method
      function Out = mtimes(obj,b)
         %MTIMES  Overloaded function for matrix multiplication
         %  Out = obj * b;
         %  --> obj : nigeLab.libs.DiskData object
         %  --> b   : Can be:
         %        --> nigeLab.libs.DiskData object
         %        --> numeric array of same size as
         %              obj.diskfile_.(obj.name_)
         %
         %  If inputs are given correctly, returned output does NOT write
         %  to a disk file, but instead simply returns the result of the
         %  multiply operation to the caller workspace
         
         varname=[ '/' obj.name_];
         a = h5read(obj.getPath,varname,[1 1],[1 inf]);
         if isa(b,'nigeLab.libs.DiskData')
            varname=[ '/' b.name_];
            b = h5read(b.getPath,varname,[1 1],[1 inf]);
            Out=a*b;
         elseif isnumeric(b)
            Out=a*b;
         end
      end
      
      % Overloaded elementwise addition method
      function Out = plus(obj,b)
         %PLUS    Overloaded function for addition on DiskData array
         %  Out = obj + b;
         %  --> obj : nigeLab.libs.DiskData object
         %  --> b   : Can be:
         %        --> nigeLab.libs.DiskData object
         %        --> numeric array of same size as
         %              obj.diskfile_.(obj.name_)
         %
         %  If inputs are given correctly, returned output does NOT write
         %  to a disk file, but instead simply returns the result of the
         %  subtraction operation to the caller workspace.
         
         Out = obj.minus(obj,-b);
      end
      
      % Overloaded cast to single method
      function Out = single(obj)
         %SINGLE Overloaded function for casting DiskData array to single
         %
         %  Out = single(obj);
         %  --> Returns value directly from file cast as `'single'` type
         
         varname=[ '/' obj.name_];
         a = h5read(obj.getPath,varname,[1 1],[1 inf]);
         Out= single(a);
      end
      
      % Overloaded size method: if file doesn't exist returns zeros
      function dim = size(obj,n)
         %SIZE  Overloaded function for getting DiskData array dimensions
         %
         %  dim = obj.size();
         %  --> Returns obj.size_, which is the "assigned" size of the
         %        DiskFile
         %
         %  dim = obj.size(n);
         %  --> Returns obj.size_(n)
         
         if nargin<2
            n=1:length(obj.size_);
         end
         if obj.checkSize()
            sz_ = obj.size_;
         else
            sz_ = zeros(1,numel(obj.size_));
         end
         dim = sz_(n);
         
      end

      % Overloaded elementwise multiplication method
      function Out = times(obj,b)
         %TIMES  Overloaded function for multiplication on DiskData array
         %  Out = obj * b;
         %  --> obj : nigeLab.libs.DiskData object
         %  --> b   : Can be:
         %        --> nigeLab.libs.DiskData object
         %        --> numeric array of same size as
         %              obj.diskfile_.(obj.name_)
         %
         %  If inputs are given correctly, returned output does NOT write
         %  to a disk file, but instead simply returns the result of the
         %  multiply operation to the caller workspace
         
         varname=[ '/' obj.name_];
         a = h5read(obj.getPath,varname,[1 1],[1 inf]);
         if isa(b,'nigeLab.libs.DiskData')
            varname=[ '/' b.name_];
            b = h5read(b.getPath,varname,[1 1],[1 inf]);
            Out=a*b;
         elseif isnumeric(b)
            Out=a.*b;
         end
      end   
      
      % Overloaded method to prevent concatenation of nigeLab.libs.DiskData
      function C = vertcat(varargin)
         %VERTCAT  Overloaded method to prevent concatenation
         %
         %  C = vertcat(obj1,obj2,...);
         %
         %  C = [obj1;obj2;...];
         
         nigeLab.utils.cprintf('Comments',...
            '[DISKDATA]: Cannot concatenate DiskData objects\n');
         C = varargin{1}; % Simply returns the first element of the array
      end
   end
   
   % HIDDEN,PUBLIC
   methods (Hidden,Access=public)
      data = getEventsFromIndexing(obj,iRow,iCol)  % Return data based on row and column indexing
      data = getStreamsFromIndexing(obj,idx)       % Return data from vector ('Hybrid' or 'MatFile') using simple indexing
      setEventsFromIndexing(obj,iRow,iCol,data)    % Set data based on indexing in iRow, iCol, and data input
      setStreamsFromIndexing(obj,idx,data)         % Set data based on indexing vector `idx` and data input
   end
   
   % SEALED,PUBLIC
   methods (Sealed,Access=public)
      % Mark that this file has completed processing
      function SetCompletedStatus(obj,tf)
         %SETCOMPLETEDSTATUS  Mark that this file has completed processing
         %
         %  SetCompletedStatus(obj);
         %  --> Sets .Complete attribute to 1 (completed)
         %
         %  SetCompletedStatus(obj,false);
         %  --> Sets .Complete attribute to 0 (incomplete)
         if nargin < 2
            tf = true;
         end
         obj.Complete = tf;
      end
      
      % Check size of object to determine if something is missing
      function flag = checkSize(obj)
         %CHECKSIZE   Returns TRUE if data on DISKFILE is NON-EMPTY
         %
         %  flag = obj.checkSize();
         %  --> Ensures orientation of data on DISKFILE is consistent with
         %      the value returned by obj.size
         %  --> Returns TRUE if data on DISKFILE is NON-EMPTY
         %
         %  Note: If DISKFILE <strong>does not exist</strong>, then
         %        checkSize returns false.
         
         if exist(obj.diskfile_,'file')==0
            flag = false;
            return;
         end
         info = h5info(obj.diskfile_);
         obj.size_ = info.Datasets.Dataspace.Size;
         flag = ~any(obj.size_ == 0);
      end
      
      % Return an attribute of the H5 Diskfile
      function attvalue = getAttr(obj,attname,verbose)
         %GETATTR  Return an attribute of the H5 Diskfile
         %
         %  attvalue = getAttr(obj,'attrName');
         %     --> Return value for 'attrName' (if it exists)
         %        --> If not a valid attribute, returned as []
         %
         %  attvalue = getAttr(obj,{'attr1','attr2'...})
         %     --> Return struct with listed attribute names as fields
         %  
         %  attvalue = getAttr(obj);
         %     --> Return all attributes with names as struct field
         %           elements and values as the field values
         %
         %  Current Attributes List:
         %  * 'Complete'  --  True: Data has been extracted to file
         %  * 'Empty'  --  True: file data contents are empty
         %  * 'Locked'  --  True: file is "locked" (read-only)
         %  * 'Block'  --  char array: Name of recording block
         %  * 'Animal'  --  char array: Name of animal (parent)
         %  * 'Tank'  --  char array: Name of tank (parent of parent)
         
         [VALID,DEF] = nigeLab.libs.DiskData.validAttributeList();
         if nargin < 2
            attname = VALID;
         end
         
         if nargin < 3
            verbose = obj.verbose_;
         end
         
         if iscell(attname)
            attvalue = struct;
            for i = 1:numel(attname)
               attvalue.(attname{i}) = getAttr(obj,attname{i});
            end
            return;
         end
         
         attidx = strcmp(attname,VALID);
         if sum(attidx) ~= 1
            error(['nigeLab:' mfilename ':BadAttribute'],...
               '[DISKDATA]: Invalid Attribute (''%s'')\n',attname);
         else % Set default value based on enumerated TYPE
            attvalue = DEF{attidx};
         end
         
         try 
            attvalue = h5readatt(obj.diskfile_,'/',attname);
         catch
            if verbose
               nigeLab.utils.cprintf('Errors*','\t\t->\t[DISKDATA]: ');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
                  'Attribute missing: ');
               nigeLab.utils.cprintf('Keywords*','''%s''\n',attname);
            end
         end
      end
      
      % Returns information struct about the diskfile
      function info = getInfo(obj)
         %GETINFO  Get info about the diskfile
         %
         %  info = getInfo(obj);
         %  --> Returns struct as would be returned by calling 
         %  >> info = getfield(h5info(obj.diskfile_),'Datasets');
         
         info = h5info(obj.diskfile_);
         info = info.Datasets;
      end
      
      % Returns the path to the diskfile source
      function Out = getPath(obj)
         %GETPATH  Function for getting path to MatFile property
         %
         %  Out = obj.getPath();
         %  --> Returns full file path to the obj.diskfile_ source
         
         Out=obj.diskfile_; % deprecated; used to be MatFile
      end
      
      % Returns true if H5 attribute 'Empty' is 0 or does not exist
      function tf = hasData(obj)
         %HASDATA  Returns true if H5 attribute 'Empty' is 0 or missing
         %
         %  tf = hasData(obj);
         %  --> Older files do not have the 'Empty' Attribute, which exists
         %        at the root group ('/') level of the h5 file. In this
         %        case, the attribute is added and defaults to zero as it
         %        is assumed these files already have data in them.
         %  --> Any new DiskData files automatically have this added on
         %        construction; if construction is called WITH data in
         %        constructor, then this is set to zero (uint8); if only 2
         %        arguments are supplied to constructor, then if the file
         %        is created but has no new data in it, this is set to one
         %        (uint8)
         
         try
            tf = logical(h5readatt(obj.diskfile_,'/','Empty'));
         catch
            tf = true;
            % Write a group attribute denoting that data file is non-empty
            h5writeatt(obj.diskfile_,'/','Empty',zeros(1,1,'uint8'));
            % Indicate this to user
            [p,f,e] = fileparts(obj.diskfile_);
            p = nigeLab.utils.shortenedPath(p);
            f = nigeLab.utils.shortenedName([f e]);
            nigeLab.utils.cprintf('Errors*','\n\t\t->\t[DISKDATA]:');
            nigeLab.utils.cprintf('Text',' Set ');
            nigeLab.utils.cprintf('Keywords*','''Empty''');
            nigeLab.utils.cprintf('Text',' H5 attribute of %s%s to ',p,f);
            nigeLab.utils.cprintf('Keywords*','0\n');
            
         end
      end
      
      % "Lock" data for write access
      function lockData(obj,verbose)
         %LOCKDATA    Method to set write access to read-only
         %
         %  lockData(obj); 
         %  --> Sets write access to read-only
         %  --> (obj.access = 'r'; obj.writable_ = false)
         
         if nargin < 2
            verbose = obj.verbose_;
         end
         
         if exist(obj.diskfile_,'file')==0
            [p,f,e] = fileparts(obj.diskfile_);
            p = nigeLab.utils.shortenedPath(p);
            f = nigeLab.utils.shortenedName([f e]);
            nigeLab.sounds.play('pop',0.35);
            dbstack();
            nigeLab.utils.cprintf('Errors*','\t\t\t->\t[DISKDATA/LOCKDATA]: ');
            nigeLab.utils.cprintf('[0.55 0.55 0.55]',' Missing diskfile_ (');
            nigeLab.utils.cprintf('Keywords*','%s%s',p,f);
            nigeLab.utils.cprintf('[0.55 0.55 0.55]',')\n');
            return;            
         end
         
         obj.writable_ = false;
         obj.access_ = 'r';
         obj.overwrite_ = false;
         
         if setAttr(obj,'Locked',true)
            col = 'Keywords*';
            str = 'Successful';
         else
            dbstack();
            col = 'Errors*';
            str = 'Unsuccessful';
         end
         % Set the actual file "write" flag AFTER modifying .Locked attr
         fileattrib(obj.diskfile_,'-w'); 
         
         if verbose
            nigeLab.utils.cprintf('Text*','\t\t\t->\t[DISKDATA/LOCKDATA]: ');
            nigeLab.utils.cprintf('Keywords*','''Locked''');
            nigeLab.utils.cprintf('Text',' property set--');
            nigeLab.utils.cprintf(col,'%s\n',str); 
         end
      end
      
      % Assign an attribute to the H5 Diskfile
      function status = setAttr(obj,attname,attvalue,varargin)
         %GETATTR  Return an attribute of the H5 Diskfile
         %
         %  setAttr(obj,'attrName',value);
         %     --> Set value for 'attrName' (if it exists)
         %        --> If not a valid attribute, status is returned as false
         %
         %  setAttr(obj,'attr1',attr1val,'attr2',attr2val,...)
         %     --> Sets all attribute values in <'name',value> list
         %
         %  Current Attributes List:
         %  * 'Complete'  --  True: Data has been extracted to file
         %  * 'Empty'  --  True: file data contents are empty
         %  * 'Locked'  --  True: file is "locked" (read-only)
         %  * 'Block'  --  char array: Name of recording block
         %  * 'Animal'  --  char array: Name of animal (parent)
         %  * 'Tank'  --  char array: Name of tank (parent of parent)
         
         [VALID,DEF] = nigeLab.libs.DiskData.validAttributeList();
         attidx = strcmp(attname,VALID);
         if sum(attidx) ~= 1
            error(['nigeLab:' mfilename ':BadAttribute'],...
               '[DISKDATA]: Invalid Attribute (''%s'')\n',attname);
         end
         val = cast(attvalue,'like',DEF{attidx});
         flag = true;         
         try 
            h5writeatt(obj.diskfile_,'/',attname,val);
         catch
            flag = false;
         end
         
         if numel(varargin) >= 2
            name = varargin{1};
            val = varargin{2};
            varargin(1:2) = []; % Remove from list
            status = horzcat(status,setAttr(obj,name,val,varargin{:})); %#ok<NODEF>
         else
            status = flag;
         end
      end
      
      % "Unlock" data for write access
      function unlockData(obj,verbose)
         %UNLOCKDATA    Method to allow write/overwrite access
         %
         %  unlockData(obj); 
         %  --> Sets write access to read/write
         %  --> (obj.access_ = 'w'; obj.writable_ = true);
         
         if nargin < 2
            verbose = obj.verbose_;
         end
         
         if exist(obj.diskfile_,'file')~=0
            fileattrib(obj.diskfile_,'+w');
         else
            [p,f,e] = fileparts(obj.diskfile_);
            p = nigeLab.utils.shortenedPath(p);
            f = nigeLab.utils.shortenedName([f e]);
            nigeLab.sounds.play('pop',0.35);
            dbstack();
            nigeLab.utils.cprintf('Errors*','\t\t\t->\t[DISKDATA/UNLOCKDATA]: ');
            nigeLab.utils.cprintf('[0.55 0.55 0.55]',' Missing diskfile_ (');
            nigeLab.utils.cprintf('Keywords*','%s%s',p,f);
            nigeLab.utils.cprintf('[0.55 0.55 0.55]',')\n');
            return;            
         end
         
         obj.writable_ = true;
         obj.access_ = 'w';
         obj.overwrite_ = true;
         
         if setAttr(obj,'Locked',false)
            col = 'Keywords*';
            str = 'Successful';
         else
            dbstack();
            col = 'Errors*';
            str = 'Unsuccessful';
         end
         
         if verbose
            nigeLab.utils.cprintf('Text*','\t\t\t->\t[DISKDATA/UNLOCKDATA]: ');
            nigeLab.utils.cprintf('Keywords*','''Locked''');
            nigeLab.utils.cprintf('Text',' property set--');
            nigeLab.utils.cprintf(col,'%s\n',str); 
         end
      end
   end
   
   % SEALED,PROTECTED
   methods (Sealed,Access=protected)
      subsasgn_MatrixData(obj,S,data)  % For assigning 'Event' obj.type_ data using subscripting
      subsasgn_VectorData(obj,S,data)  % For assigning 'Hybrid' and 'MatFile' obj.type_ data using subscripting
      data = subsref_MatrixData(obj,S) % Returns 'Event' obj.type_ data using subscripting
      data = subsref_VectorData(obj,S) % Returns 'Hybrid' or 'MatFile' obj.type_ data using subscripting
   end
   
   % NO ATTRIBUTES (overloaded get, set methods)
   methods 
      % % % GET.PROPERTY METHODS % % % % % % % % % % % %
      % [DEPENDENT]  Returns .Animal property: char name of animal
      function value = get.Animal(obj)
         %GET.ANIMAL  Returns .Animal property (char name of animal)
         %
         %  value = get(obj,'Animal'); 
         %  --> Value is char array or empty '' if attribute not set
         
         value = char.empty();
         if isempty(obj.diskfile_)
            return;
         end
         value = getAttr(obj,'Animal');
      end
      
      % [DEPENDENT]  Returns .Block property: char name of recording block
      function value = get.Block(obj)
         %GET.BLOCK  Returns .Block property (char name of recording)
         %
         %  value = get(obj,'Block'); 
         %  --> Value is char array or empty '' if attribute not set
         
         value = char.empty();
         if isempty(obj.diskfile_)
            return;
         end
         value = getAttr(obj,'Block');
      end
      
      % [DEPENDENT]  Returns .Complete property: if true, file has all data
      function value = get.Complete(obj)
         %GET.COMPLETE  Returns .Complete property (is data in file good?)
         %
         %  value = get(obj,'Complete'); 
         %  --> Value is logical true or false (scalar)
         %  --> false indicates that either:
         %     * No data is present in the file, or
         %     * The file in general is missing actual (experimental) data
         %        + For example, a file may be initialized to have the
         %        correct number of samples, but as an "all-zeroes"
         %        place-holder MatFile; this would still result in a 'True'
         %        value for Empty.
         %  --> Note: This must be set manually by the user.
         
         value = logical.empty();
         if isempty(obj.diskfile_)
            return;
         end
         value = getAttr(obj,'Complete');
         value = logical(value);
         % If not complete, then check .Index
         if ~value
            % If .Index == length() of dataset and .type_ == 'MatFile'
            % then data is "complete" because it cannot be extended further
            % along either dimension.
            if ~isempty(obj.Index) && strcmp(obj.type_,'MatFile')
               value = (obj.Index == length(obj)) && (length(obj) > 1);
               if value
                  unlockData(obj,false); % Suppress text output
                  setAttr(obj,'Complete',value);
                  lockData(obj,false); % Suppress text output
               end
            end
         end
      end
      
      % [DEPENDENT]  Returns .Empty property: if true, file has no data
      function value = get.Empty(obj)
         %GET.EMPTY  Returns .Empty property (is file blank?)
         %
         %  value = get(obj,'Empty'); 
         %  --> Value is logical true or false (scalar)
         %  --> true indicates that either:
         %     * No data is present in the file
         %  --> Note: This must be set manually by the user.
         
         value = logical.empty();
         if isempty(obj.diskfile_)
            return;
         end
         value = getAttr(obj,'Empty');
         value = logical(value);
      end
      
      % [DEPENDENT]  Returns .Locked property: if true, file has no data
      function value = get.Locked(obj)
         %GET.EMPTY  Returns .Locked property (is file read-only?)
         %
         %  value = get(obj,'Locked'); 
         %  --> Value set to true on call of `lockData`
         %  --> Value set to false on call of `unlockData`
         
         value = logical.empty();
         if isempty(obj.diskfile_)
            return;
         end
         value = getAttr(obj,'Locked');
         value = logical(value);
      end
      
      % [DEPENDENT]  Returns .File property
      function value = get.File(obj)
         %GET.FILE  Returns .File property (char array filename)
         %
         %  value = get(obj,'File'); 
         %  Returns char array full filename of .mat file pointed to by
         %  obj.diskfile_ (protected property)
         
         value = '';
         if isempty(obj.diskfile_)
            return;
         end
         value = nigeLab.utils.getUNCPath(obj.diskfile_);
      end
      
      % [DEPENDENT]  Returns .Index property (current "data cursor")
      function value = get.Index(obj)
         %GET.INDEX  Returns .Index property (current "data cursor")
         %
         %  value = get(obj,'Index');
         %
         %  --> Default value is 1. Returns value stored in obj.index_
         %  --> Automatically updated if .append() method is used
         %  --> Probably useful for indexing into the DiskData files when
         %        assigning streams that are sampled asynchronously and you
         %        are going through "hyperslabs" of time/sample indices
         
         value = double.empty();
         if isempty(obj.diskfile_)
            return;
         end
         value = getAttr(obj,'Index');
      end
      
      % [DEPENDENT]  Returns .Tank property: char name of "grouping" tank
      function value = get.Tank(obj)
         %GET.TANK Returns .Tank property (char name of "grouping" tank)
         %
         %  value = get(obj,'Tank'); 
         %  --> Value is char array or empty '' if attribute not set
         
         value = char.empty();
         if isempty(obj.diskfile_)
            return;
         end
         value = getAttr(obj,'Tank');
      end
      
      % [DEPENDENT] Returns .chunks_h5 property
      function value = get.chunks_h5(obj)
         %GET.CHUNKS  Returns .chunks_h5 property
         %
         %  value = get(obj,'chunks_h5');
         %  --> Returns value depending on obj.type_
         
         value = [];
         if isempty(obj.type_)
            return;
         end
         switch obj.type_
            case 'MatFile'
               return; % No chunking; it is contiguous
            case 'Hybrid'
               value = obj.chunks_;
            case 'Event'
               if isempty(obj.size_)
                  return;
               end
               value = [1 obj.size_(2)]; 
         end
               
      end
      
      % [DEPENDENT] Returns .const_dim_ext property
      function value = get.const_dim_ext(obj)
         %GET.CONST_DIM_EXT  Returns .const_dim_ext property
         %
         %  value = get(obj,'const_dim_ext');
         %  --> Returns value of "constant" dimension. Depends on obj.type_
         
         value = [];
         if isempty(obj.const_dim_idx)
            return;
         elseif isempty(obj.size_)
            return;
         end
         value = obj.size_(obj.const_dim_idx);
               
      end
      
      % [DEPENDENT] Returns .const_dim_idx property
      function value = get.const_dim_idx(obj)
         %GET.CONST_DIM_IDX  Returns .const_dim_idx property
         %
         %  value = get(obj,'const_dim_idx');
         %  --> Returns index of "constant" dimension. Depends on obj.type_
         
         value = [];
         if isempty(obj.type_)
            return;
         end
         switch obj.type_
            case 'MatFile'
               value = [1,2]; % Both are constant
            case 'Hybrid'
               value = 1;
            case 'Event'
               value = 2;
         end
      end
      
      % [DEPENDENT]  Returns .class_h5 property
      function value = get.class_h5(obj)
         %GET.CLASS_H5  Returns .class_h5 property (from obj.class_)
         %
         %  value = get(obj,'class_h5'); 
         %  Returns char array for h5 constant corresponding to obj.class_
         
         value = '';
         if isempty(obj.class_)
            return;
         end
         % Otherwise, use a switch statement to convert
         switch lower(obj.class_)
            case 'double'
               value = 'H5T_NATIVE_DOUBLE';
            case 'single'
               value = 'H5T_NATIVE_FLOAT';
            case 'int32'
               value = 'H5T_NATIVE_INT32';
            case 'uint16'
               value = 'H5T_NATIVE_UINT16';
            case 'uint32'
               value = 'H5T_NATIVE_UINT32';               
            case 'uint8'
               value = 'H5T_NATIVE_UINT8';
            case 'int8'
               value = 'H5T_NATIVE_INT8';
            case 'char'
               value = 'H5T_NATIVE_CHAR';
            otherwise
               error(['nigeLab:' mfilename ':BadClass'],...
                  '[DISKDATA]: Unexpected value of obj.class_: ''%s''',...
                  obj.class_);
         end
      end
      
      % [DEPENDENT] Returns .data property (all .type_)
      function value = get.data(obj)
         %GET.DATA  Returns .data property (all data)
         %
         %  value = get(obj,'data');
         %  --> Returns all data in disk file
         
         value = [];
         if ~checkSize(obj)
            return;
         end
         N = obj.size_(1);
         varname_ = ['/' obj.name_];
         value = h5read(obj.diskfile_,varname_,[1 1],obj.size_);
      end
      
      % [DEPENDENT]  Returns .dims_h5 property (fliplr(obj.size_))
      function value = get.dims_h5(obj)
         %GET.DIMS_H5  Returns .dims property (from obj.size_)
         %
         %  value = get(obj,'dims_h5'); 
         %  --> returns >> fliplr(obj.size_);
         
         value = [];
         if isempty(obj.size_)
            return;
         end
         % Otherwise, it is just obj.size_ transposed
         value = fliplr(obj.size_);
      end
      
      % [DEPENDENT]  Returns .maxdims_h5 property
      function value = get.maxdims_h5(obj)
         %GET.MAXDIMS_H5  Returns .maxdims_h5 property (from .size_,.type_)
         %
         %  value = get(obj,'class_h5'); 
         %  Returns numeric maximum dimensions dependent mainly on .type_
         
         value = [];
         if isempty(obj.type_)
            return;
         elseif isempty(obj.size_)
            return;
         end
         % Value depends on obj.type_
         value = obj.size_;
         value(obj.var_dim_idx) = inf; 
      end
      
      % [DEPENDENT]  Returns .rank_h5 property
      function value = get.rank_h5(obj)
         %GET.RANK_H5  Returns .class_h5 property (from obj.class_)
         %
         %  value = get(obj,'rank_h5'); 
         %  Returns rank of h5 memory space based on obj.type_ and
         %  obj.size_
         
         value = 2;
         if isempty(obj.type_)
            return;
         end
         % Otherwise, use a switch statement to convert
         switch lower(obj.type_)
            case 'matfile'
               return; % Rank is 2
            case 'hybrid'
               return; % Rank is 2
            case 'event'
               if isempty(obj.size_)
                  return; % Rank is 2
               else
                  value = numel(obj.size_);
               end

            otherwise
               return;
         end
      end
      
      % [DEPENDENT] Returns .snippet property
      function value = get.snippet(obj)
         %GET.SNIPPET  Returns .snippet prop (column 5+ if .type_ == Event)
         %
         %  value = get(obj,'snippet');
         %  --> Returns "snippet" of Event
         
         value = [];
         if isempty(obj.type_)
            return;
         elseif ~checkSize(obj)
            return;
         end
         switch obj.type_
            case 'MatFile'
               nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
                  'No field: %s (for ''MatFile'' DiskData.type_)\n',...
                  'snippet');
               return;
            case 'Hybrid'
               nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
                  'No field: %s (for ''Hybrid'' DiskData.type_)\n',...
                  'snippet');
               return;
            case 'Event'
               nCol = obj.size_(2) - 4;
               N = obj.size_(1);
               varname_ = ['/' obj.name_];
               value = h5read(obj.diskfile_,varname_,[1,5],[N,nCol]);
         end
      end
      
      % [DEPENDENT] Returns .tag property
      function value = get.tag(obj)
         %GET.TAG  Returns .tag property (column 3 for .type_ == Event)
         %
         %  value = get(obj,'tag');
         %  --> Returns "tag" of Event
         
         value = [];
         if isempty(obj.type_)
            return;
         elseif ~checkSize(obj)
            return;
         end
         switch obj.type_
            case 'MatFile'
               nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
                  'No field: %s (for ''MatFile'' DiskData.type_)\n',...
                  'tag');
               return;
            case 'Hybrid'
               nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
                  'No field: %s (for ''Hybrid'' DiskData.type_)\n',...
                  'tag');
               return;
            case 'Event'
               N = obj.size_(1);
               varname_ = ['/' obj.name_];
               value = h5read(obj.diskfile_,varname_,[1,3],[N,1]);
         end
      end
      
      % [DEPENDENT] Returns .ts property
      function value = get.ts(obj)
         %GET.TS  Returns .type property (column 4 for .type_ == Event)
         %
         %  value = get(obj,'ts');
         %  --> Returns "ts" of Event
         
         value = [];
         if isempty(obj.type_)
            return;
         elseif ~checkSize(obj)
            return;
         end
         switch obj.type_
            case 'MatFile'
               nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
                  'No field: %s (for ''MatFile'' DiskData.type_)\n',...
                  'type');
               return;
            case 'Hybrid'
               nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
                  'No field: %s (for ''Hybrid'' DiskData.type_)\n',...
                  'type');
               return;
            case 'Event'
               N = obj.size_(1);
               varname_ = ['/' obj.name_];
               value = h5read(obj.diskfile_,varname_,[1,4],[N,1]);
         end
      end
      
      % [DEPENDENT] Returns .type property
      function value = get.type(obj)
         %GET.TYPE  Returns .type property (column 1 for .type_ == Event)
         %
         %  value = get(obj,'type');
         %  --> Returns "type" of Event
         
         value = [];
         if isempty(obj.type_)
            return;
         elseif ~checkSize(obj)
            return;
         end
         switch obj.type_
            case 'MatFile'
               nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
                  'No field: %s (for ''MatFile'' DiskData.type_)\n',...
                  'type');
               return;
            case 'Hybrid'
               nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
                  'No field: %s (for ''Hybrid'' DiskData.type_)\n',...
                  'type');
               return;
            case 'Event'
               N = obj.size_(1);
               varname_ = ['/' obj.name_];
               value = h5read(obj.diskfile_,varname_,[1,1],[N,1]);
         end
      end
      
      % [DEPENDENT] Returns .var_dim_idx property
      function value = get.var_dim_idx(obj)
         %GET.VAR_DIM_IDX  Returns .var_dim_idx property
         %
         %  value = get(obj,'var_dim_idx');
         %  --> Returns index of "variable" dimension. Depends on obj.type_
         
         value = [];
         if isempty(obj.type_)
            return;
         end
         switch obj.type_
            case 'MatFile'
               value = []; % Size remains fixed
            case 'Hybrid'
               value = 2; % Append along columns
            case 'Event'
               value = 1; % Append along rows
         end
      end
      
      % [DEPENDENT] Returns .value property
      function value = get.value(obj)
         %GET.VALUE  Returns .value property (column 2 for .type_ == Event)
         %
         %  value = get(obj,'value');
         %  --> Returns "value" of Event file
         
         value = [];
         if isempty(obj.type_)
            return;
         elseif ~checkSize(obj)
            return;
         end
         switch obj.type_
            case 'MatFile'
               nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
                  'No field: %s (for ''MatFile'' DiskData.type_)\n',...
                  'value');
               return;
            case 'Hybrid'
               nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
                  'No field: %s (for ''Hybrid'' DiskData.type_)\n',...
                  'value');
               return;
            case 'Event'
               N = obj.size_(1);
               varname_ = ['/' obj.name_];
               value = h5read(obj.diskfile_,varname_,[1,2],[N,1]);
         end
      end
      % % % % % % % % % % END GET.PROPERTY METHODS % % %
      
      % % % SET.PROPERTY METHODS % % % % % % % % % % % %
      % [DEPENDENT]  Assigns .Animal property: char name of animal
      function set.Animal(obj,value)
         %GET.ANIMAL  Assigns .Animal property (char name of animal)
         %
         %  set(obj,'Animal',value); 
         %  --> Value is char array or empty '' if attribute not set
         
         if isempty(obj.diskfile_)
            return;
         end
         if setAttr(obj,'Animal',value)
            col = 'Keywords*';
            str = 'Successful';
         else
            col = 'Errors*';
            str = 'Unsuccessful';
         end
         
         if obj.verbose_
            nigeLab.utils.cprintf('Text*','\t\t\t->\t[DISKDATA]: ');
            nigeLab.utils.cprintf('Keywords*','''Animal''');
            nigeLab.utils.cprintf('Text',' property set--');
            nigeLab.utils.cprintf(col,'%s\n',str); 
         end
      end
      
      % [DEPENDENT]  Assigns .Block property: char name of recording block
      function set.Block(obj,value)
         %GET.BLOCK  Assigns .Block property (char name of recording)
         %
         %  set(obj,'Block',value); 
         %  --> Value is char array or empty '' if attribute not set
         
         if isempty(obj.diskfile_)
            return;
         end
         if setAttr(obj,'Block',value)
            col = 'Keywords*';
            str = 'Successful';
         else
            col = 'Errors*';
            str = 'Unsuccessful';
         end
         
         if obj.verbose_
            nigeLab.utils.cprintf('Text*','\t\t\t->\t[DISKDATA]: ');
            nigeLab.utils.cprintf('Keywords*','''Block''');
            nigeLab.utils.cprintf('Text',' property set--');
            nigeLab.utils.cprintf(col,'%s\n',str); 
         end
      end
      
      % [DEPENDENT]  Assigns .Complete property: if true, file has all data
      function set.Complete(obj,value)
         %SET.COMPLETE  Assigns .Complete property (is data in file good?)
         %
         %  set(obj,'Complete',value); 
         %  --> Value is logical true or false (scalar)
         %  --> false indicates that either:
         %     * No data is present in the file, or
         %     * The file in general is missing actual (experimental) data
         %        + For example, a file may be initialized to have the
         %        correct number of samples, but as an "all-zeroes"
         %        place-holder MatFile; this would still result in a 'True'
         %        value for Empty.
         %  --> Note: This must be set manually by the user.

         if isempty(obj.diskfile_)
            return;
         end
         
         if setAttr(obj,'Complete',value)
            col = 'Keywords*';
            str = 'Successful';
         else
            col = 'Errors*';
            str = 'Unsuccessful';
         end
         
         if obj.verbose_
            nigeLab.utils.cprintf('Text*','\t\t\t->\t[DISKDATA]: ');
            nigeLab.utils.cprintf('Keywords*','''Complete''');
            nigeLab.utils.cprintf('Text',' property set--');
            nigeLab.utils.cprintf(col,'%s\n',str); 
         end
      end
      
      % [DEPENDENT]  Assigns .Empty property: if true, file has no data
      function set.Empty(obj,value)
         %SET.EMPTY  Sets .Empty property (is file blank?)
         %
         %  value = set(obj,'Empty',value); 
         %  --> Value is logical true or false (scalar)
         %  --> true indicates that either:
         %     * No data is present in the file
         %  --> Note: This must be set manually by the user.
         
         if isempty(obj.diskfile_)
            return;
         end
         
         if setAttr(obj,'Empty',value)
            col = 'Keywords*';
            str = 'Successful';
         else
            col = 'Errors*';
            str = 'Unsuccessful';
         end
         
         if obj.verbose_
            nigeLab.utils.cprintf('Text*','\t\t\t->\t[DISKDATA]: ');
            nigeLab.utils.cprintf('Keywords*','''Empty''');
            nigeLab.utils.cprintf('Text',' property set--');
            nigeLab.utils.cprintf(col,'%s\n',str);    
         end
      end
      
      % [DEPENDENT]  Assigns .File property (does nothing)
      function set.File(~,~)
         %SET.FILE  (does nothing)
         if obj.verbose_
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: File\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .Locked property: if true, file is read-only
      function set.Locked(obj,value)
         %SET.EMPTY  Sets .Locked property (is file read-only?)
         %
         %  value = set(obj,'Locked',value); 
         %  --> Value is logical true or false (scalar)
         %  --> true indicates that file is read-only (lockData)
         %  --> false indicates that file has write-access (unlockData)
         
         if ~islogical(value)
            error(['nigeLab:' mfilename ':BadClass'],...
               '[DISKDATA/SET.LOCKED]: value must be logical');
         elseif isempty(obj.diskfile_)
            return;
         end
         
         % Mediate this via "lockData"/"unlockData"
         % Note: this is OK because property value not stored in the class,
         % it is stored as the attribute; therefore, this will not lead to
         % a recursive call since none of the attribute setting or
         % lock/unlock methods set .Locked property
         if value
            lockData(obj); 
         else
            unlockData(obj);
         end
                 
      end
      
      % [DEPENDENT]  Assigns .Index property (current "data cursor")
      function set.Index(obj,value)
         %SET.INDEX  Assigns .Index property (current "data cursor")
         %
         %  vset(obj,'Index');
         %
         %  --> Default value is 1. Returns value stored in obj.index_
         %  --> Automatically updated if .append() method is used
         %  --> Probably useful for indexing into the DiskData files when
         %        assigning streams that are sampled asynchronously and you
         %        are going through "hyperslabs" of time/sample indices
         
         if isempty(obj.diskfile_)
            return;
         end
         
         if setAttr(obj,'Index',value)
            col = 'Keywords*';
            str = 'Successful';
         else
            col = 'Errors*';
            str = 'Unsuccessful';
         end
         
         if obj.verbose_
            nigeLab.utils.cprintf('Text*','\t\t\t->\t[DISKDATA]: ');
            nigeLab.utils.cprintf('Keywords*','''Index''');
            nigeLab.utils.cprintf('Text',' property set--');
            nigeLab.utils.cprintf(col,'%s\n',str); 
         end
      end
      
      % [DEPENDENT]  Assigns .Tank property: char name of animal "grouping"
      function set.Tank(obj,value)
         %GET.TANK  Assigns .Tank property (char name of animal "grouping")
         %
         %  set(obj,'Tank',value); 
         %  --> Value is char array or empty '' if attribute not set
         
         if isempty(obj.diskfile_)
            return;
         end
         if setAttr(obj,'Tank',value)
            col = 'Keywords*';
            str = 'Successful';
         else
            col = 'Errors*';
            str = 'Unsuccessful';
         end
         
         if obj.verbose_
            nigeLab.utils.cprintf('Text*','\t\t\t->\t[DISKDATA]: ');
            nigeLab.utils.cprintf('Keywords*','''Tank''');
            nigeLab.utils.cprintf('Text',' property set--');
            nigeLab.utils.cprintf(col,'%s\n',str); 
         end
      end
      
      % [DEPENDENT]  Assigns .chunks_h5 property (does nothing)
      function set.chunks_h5(~,~)
         %SET.CHUNKS_H5  (does nothing)
         if obj.verbose_
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: chunks_h5\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .class_h5 property (does nothing)
      function set.class_h5(~,~)
         %SET.CLASS_H5  (does nothing)
         if obj.verbose_
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: class_h5\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .const_dim_ext property (does nothing)
      function set.const_dim_ext(~,~)
         %SET.CONST_DIM_EXT  (does nothing)
         if obj.verbose_
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: const_dim_ext\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .const_dim_idx property (does nothing)
      function set.const_dim_idx(~,~)
         %SET.CONST_DIM_IDX  (does nothing)
         if obj.verbose_
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: const_dim_idx\n');
            fprintf(1,'\n');
         end
      end

      % [DEPENDENT]  Assigns .data property (assign full data array)
      function set.data(obj,value)
         %SET.DATA  Assign full data array
         %
         %  set(obj,'data',value)
         
         obj(:,:) = value;         
      end
      
      % [DEPENDENT]  Assigns .dims_h5 property (does nothing)
      function set.dims_h5(~,~)
         %SET.DIMS_H5  (does nothing)
         if obj.verbose_
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: dims_h5\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .maxdims_h5 property (does nothing)
      function set.maxdims_h5(~,~)
         %SET.MAXDIMS_H5  (does nothing)
         if obj.verbose_
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: maxdims_h5\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .snippet property ('Event' type only)
      function set.snippet(obj,value)
         %SET.SNIPPET  Assign data to `snippet` (column 5+)
         %
         %  set(obj,'snippet',value)
         
         if strcmp(obj.type_,'Event')
            obj(:,5:(5+size(value,2))) = value; 
         end
      end
      
      % [DEPENDENT]  Assigns .tag property ('Event' type only)
      function set.tag(obj,value)
         %SET.TAG Assign data to `tag` (column 3)
         %
         %  set(obj,'tag',value)
         
         if strcmp(obj.type_,'Event')
            obj(:,3) = value; 
         end
      end
      
      % [DEPENDENT]  Assigns .ts property ('Event' type only)
      function set.ts(obj,value)
         %SET.TS Assign data to `ts` (column 4)
         %
         %  set(obj,'ts',value)
         
         if strcmp(obj.type_,'Event')
            obj(:,4) = value; 
         end
      end
      
      % [DEPENDENT]  Assigns .type property ('Event' type only)
      function set.type(obj,value)
         %SET.TYPE Assign data to `type` (column 1)
         %
         %  set(obj,'type',value)
         
         if strcmp(obj.type_,'Event')
            obj(:,1) = value; 
         end
      end
      
      % [DEPENDENT]  Assigns .rank_h5 property (does nothing)
      function set.rank_h5(~,~)
         %SET.RANK_H5  (does nothing)
         if obj.verbose_
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: rank_h5\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .value property ('Event' type only)
      function set.value(obj,value)
         %SET.VALUE  Assign data to to `value`
         %
         %  set(obj,'value',value)
         
         if strcmp(obj.type_,'Event')
            obj(:,2) = value; 
         end
      end
      
      % [DEPENDENT]  Assigns .var_dim_idx property (does nothing)
      function set.var_dim_idx(~,~)
         %SET.VAR_DIM_IDX  (does nothing)
         if obj.verbose_
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[DISKDATA]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property:var_dim_idx\n');
            fprintf(1,'\n');
         end
      end
      % % % % % % % % % % END SET.PROPERTY METHODS % % %
   end
   
   % PROTECTED
   methods (Access=protected)
      % Method to add filename attributes (primarily during init)
      function addFileNameAttributes(obj,fName)
         %ADDFILENAMEATTRIBUTES  Adds filename attributes (Block etc) 
         %
         %  addFileNameAttributes(obj);
         
         if nargin < 2
            fName = obj.diskfile_;
         end
         p = fileparts(fName); % Sub-folder in Block
         p = fileparts(p); % Block path
         [p,block] = fileparts(p); % [Animal path, Block]
         obj.Block = block;
         [p,animal] = fileparts(p); % [Tank path, Animal]
         obj.Animal = animal;
         [~,tank] = fileparts(p); % [Experiment path, Tank]
         obj.Tank = tank;
      end
      
      % Overloaded method for displaying object to the command window
      function Out = displayScalarObject(obj)
         %DISPLAYSCALAROBJECT  Overloaded function for printing DiskData 
         %                       elements to command window
         
         if isempty(obj)
            nigeLab.sounds.play('pop',0.35);
            nigeLab.utils.cprintf('Errors*','[DISKDATA]: '); 
            nigeLab.utils.cprintf('Errors','Empty object.\n'); 
            Out = [];
            return;
         elseif ~isvalid(obj)
            nigeLab.sounds.play('pop',0.35);
            nigeLab.utils.cprintf('Errors*','[DISKDATA]: '); 
            nigeLab.utils.cprintf('Errors','Object is invalid.\n'); 
            Out = [];
            return;
         end
         
         if exist(obj.diskfile_,'file')==0
            nigeLab.sounds.play('pop',0.35);
            nigeLab.utils.cprintf('Errors*','[DISKDATA]: '); 
            nigeLab.utils.cprintf('Errors','No such file--'); 
            nigeLab.utils.cprintf('Keywords*','%s\n',obj.diskfile_);
            Out = [];
            return;
         end
         varname_ = [ '/' obj.name_];
         switch obj.type_
            case 'Hybrid'
               if nargout>0
                  Out=[];
               end
               a = h5read(obj.getPath,varname_,[1 1],[1 inf]);
               disp(a);
            case 'MatFile'
               if nargout>0
                  Out=[];
               end
               a = h5read(obj.getPath,varname_,[1 1],[1 inf]);
               disp(a);
            case 'Event'
               a = h5read(obj.getPath,varname_,[1 1],[inf inf]);
               disp(a);
               if nargout > 0
                  Out = [];    
               end
            otherwise
               error(['nigeLab:' mfilename ':BadType'],...
                  'Unknown type: %s',obj.type_);
         end
      end
      
      % Returns file size (bytes)
      function [fsize,dname,dclass,sz] = getFileSize(obj)
         %GETFILESIZE  Returns file size (bytes)
         %
         %  fsize = obj.getFileSize();
         %  [fsize,dname,dclass,sz] = getFileSize(obj);
         
         info = h5info(obj.diskfile_);
         if numel(info.Datasets) > 1
            curSz = 0;
            idx = 1;
            for i = 1:numel(info.Datasets)
               sz = max(info.Datasets(i).Dataspace.Size);
               if sz > curSz
                  idx = i;
                  curSz = sz;
               end
            end
         else
            idx = 1;            
         end
         sz = info.Datasets(idx).Dataspace.Size;
         fsize = prod([sz,info.Datasets.Datatype.Size]);
         dname = info.Datasets(idx).Name;
         if isempty(info.Datasets(idx).Attributes)
            dclass = 'double';
         else
            dclass = info.Datasets(idx).Attributes.Value;
         end
      end
      
      % Returns "Footer" text describing object
      function s = getFooter(obj)
         %GETFOOTER  Returns "footer" text describing object
         %
         %  s = obj.getFooter();
         
         s = '';
         switch obj.type_
            case 'Event'
               [~,f,~] = fileparts(obj.diskfile_);
               f = strsplit(f,'_');
               f = f{1};
               fprintf(1,'\n\t');
               nigeLab.utils.cprintf('_Strings',...
                  '%s with %g events\n',...
                  f,obj.size_(1));
               str = {'type','value','tag','ts','snippet'};
               for ii = 1:numel(str)
                  if any(obj.(str{ii})~=0)
                     nigeLab.utils.cprintf('Keywords*',...
                        '--->\t\t %s ',str{ii});...
                     nigeLab.utils.cprintf('Text',...
                     'contains data.\n');
                  else
                     nigeLab.utils.cprintf('[0.4 0.4 0.4]',...
                        '->\t %s contains only zeros.\n',str{ii});
                  end
               end 
               fprintf(1,'\n');
            otherwise
               
         end
      end
      
      % Returns index to correct array element of info struct
      function idx = getWhosIndex(obj,info)
         %GETWHOSINDEX  Return index to correct element of struct from whos
         %
         %  idx = getWhosIndex(obj,info);
         %  
         %  obj : nigeLab.libs.DiskData object
         %  info : Struct or struct array as returned by 
         %  >> whos(obj.diskfile_.(obj.name_));
         %
         %  If multiple variables are saved in the diskfile, then this will
         %  find the correct struct array element based on obj.name_
         
         if ~isscalar(info)
            if isfield(info,'name') % From whos
               varNames = {info.name};
            else % From h5info
               varNames = {info.Name};
            end
            idx = find(ismember(obj.name_,varNames),1,'first');
            if isempty(idx)
               [p,f,e] = fileparts(fName);
               p = nigeLab.utils.shortenedPath(p);
               f = nigeLab.utils.shortenedPath([f e]);

               nigeLab.utils.cprintf('Errors*','/t/t->/t[DISKDATA]: ');
               nigeLab.utils.cprintf('Errors',...
                  'File %s%s contains the following variables-\n',p,f);
               nigeLab.utils.cprintf('[0.5 0.5 0.5]*',...
                  '\t\t\t->\t%s\n',varNames{:});
               nigeLab.utils.cprintf('Comments',...
                  ['If this is an OLD-format file, ' ...
                  'must provide ''name'' as part of input ''name'', ' ...
                  'value argument pairs\n']);
               error(['nigeLab:' mfilename ':BadFormat'],...
                  'No variable: %s (<-- obj.name_)',obj.name_);
            end
         else
            idx = 1;
         end
      end
      
      % Initialize `Event` type_ file
      function initEventFile(obj,fName)
         %INITEVENTFILE   Initialize `'Event'` type_ file
         %
         %  flag = initEventFile(obj,fName);
         %
         %  obj : nigeLab.libs.DiskData object
         %  fName : Char array pointing to obj.diskfile_ source
         %
         %  flag : Returns true if the file already existed before init
         %
         %  Initializes DiskData when file type is 'Event' (used for
         %  Spikes, Features, and other values related to discrete Events)

         % If the file does not already exist
         initHybridFile(obj,fName); % Same as initHybridFile
      end
      
      % Initialize data to file specified by fName for .type_ = 'Hybrid'
      function initHybridFile(obj,fName)
         %INITHYBRIDFILE  Init data in file specified by fName for 'Hybrid'
         %
         %  flag = initHybridFile(obj,fName);
         %
         %  obj : nigeLab.libs.DiskData object
         %  fName : Full file character array to obj.diskfile_ source
         %
         %  flag : Presence (true) or absence (false) of file initially         
         % Same initial step
         
         % Initialize the file
         if initMatFile(obj,fName) % if already data, re-save it
            return;
         end % Otherwise, file was created `de novo`
         
         % Set the file for write access
         if isunix
            fileattrib(fName,'+w','a');
         else
            fileattrib(fName,'+w','','s');
         end
         
         % Remove link to existing `data` variable (dataset; obj.name_)
         fid = H5F.open(fName,'H5F_ACC_RDWR','H5P_DEFAULT');
         H5L.delete(fid,'data','H5P_DEFAULT');
         H5F.close(fid);
         
         % Get dataset name (varname_)
         varname_ = ['/' obj.name_]; 
         
         % Now, create h5 dataset with (correct) desired property list
         if strcmp(obj.type_,'MatFile') % MatFile ~ not extendable
            h5create(fName, varname_, obj.maxdims_h5,...
               'DataType',obj.class_,'FillValue',zeros(1,1,obj.class_));

         else % Event, Hybrid
            h5create(fName, varname_, obj.maxdims_h5,...
               'ChunkSize',obj.chunks_h5,'DataType',obj.class_,...
               'Deflate',obj.compress_,'FillValue',zeros(1,1,obj.class_));
         end
         % Denote that the file is empty (initialized only)
         obj.Empty = ones(1,1,'int8');
         % Parse other metadata attributes from filename
         addFileNameAttributes(obj,fName);
      end
      
      % Initialize data in file specified by fName for .type_ = 'MatFile'
      function flag = initMatFile(obj,fName)
         %INITMATFILE  Init data to file specified by fName
         %
         %  flag = initMatFile(obj,fName);
         %
         %  obj : nigeLab.libs.DiskData object
         %  fName : Char array with full file path to obj.diskfile_
         %
         %  flag : Returns true if data was there to begin with.
         %
         % This allows instantiation of the variable to be
         % loaded from the MatFile. All the large data streams
         % are saved with 'data' as the name of the long
         % variable. However, some files may have a different
         % name for the variable that you wish to access, such
         % as 'spikes' or 'features' in the SPIKES file (old versions)
         
         if isa(fName,'matlab.io.MatFile')
            obj.diskfile_ = fName.Properties.Source;
            info = whos(fName);
            idx = getWhosIndex(obj,info);
            obj.size_ = info(idx).size;
            obj.bytes_ = info(idx).bytes;
            obj.class_ = info(idx).class;
            flag = true;
            return;
         elseif ~ischar(fName)
            error(['nigeLab:' mfilename ':BadClass'],...
               '[DISKDATA]: Data format not yet supported');
         end
         % Flag indicates presence or absence of file
         flag = exist(fName,'file')~=0;
         if ~flag % If file is missing
            % By default: obj.name_ = 'data'
            data = ones(1,1,obj.class_); %#ok<PROPLC>
            save(fName,'data','-v7.3');
            % Switch to `Hybrid`, since this MUST be expanded
            obj.type_ = 'Hybrid';
         end
         
         obj.diskfile_ = fName;
          % And parse information about the file itself
         [b,n,c,s] = getFileSize(obj);
         obj.bytes_ = b;
         obj.name_ = n;
         obj.class_ = c;
         obj.size_ = s;
         
         if flag % It exists, so overwrite and correct format
            if isempty(obj.Block)
               % Get dataset name (varname_)
               varname_ = ['/' obj.name_]; 
               obj.overwrite_ = true; % (overwrite file to correct format)
               saveFile(obj,fName,h5read(fName,varname_));
            end
         end
      end
      
      % Save data to file
      function saveFile(obj,fName,data,type)
         %SAVEFILE  Save data file
         %
         %  saveFile(obj,fName,data);
         %
         %  obj : nigeLab.libs.DiskData object
         %  fName : char array full file path to obj.diskfile_ source
         %  data : Data to be written to the diskfile
         
         if nargin < 4
            type = obj.type_;
         end
         
         if isempty(data)
            error(['nigeLab:' mfilename ':BadInit'],...
               ['[DISKDATA]: Cannot write EMPTY array to file. '...
               '\t->\t(Check constructor)\n']);
         end
         
         if exist(fName,'file')~=0 
            if obj.overwrite_
               delete(fName);
            else
               error(['nigeLab:' mfilename ':BadAccess'],...
               ['[DISKDATA]: Constructor was called with all three ' ...
               'input args, but overwrite_ was not explicitly set, and ' ...
               'the file (%s) already exists. Please either specify ' ...
               '%s''overwrite'', true%s in the %s''name'', value%s input ' ...
               'arguments to the constructor, or double-check that ' ...
               'you really want to overwrite the contents of that file.\n'],...
               fName,'<','>','<','>');
            end
         end          
         % Parse some variables from the data and any optional input args
         obj.size_=size(data);
         obj.class_=class(data);
         % Create a small file to initialize with the proper '.mat' header
         tmp = data;
         data = ones(1,1,obj.class_); %#ok<PREALL>
         save(fName,'data','-v7.3');
         data = tmp;
         % Properties depend on the kind of file
         switch lower(type)
            case 'matfile' % MatFile is not extendable
               obj.type_ = 'MatFile'; % Formatting
            case 'hybrid' % Hybrid can be extended along columns
               obj.type_ = 'Hybrid'; % formatting               
            case {'event','events'}
               obj.type_ = 'Event'; % formatting
            otherwise
               error(['nigeLab:' mfilename ':BadType'],...
                  '[DISKDATA]: Unknown data format (obj.type_: ''%s'')',...
                  obj.type_);
         end         
         % Remove link to existing `data` variable (dataset; obj.name_)
         varname_ = ['/' obj.name_];
         if isunix
            fileattrib(fName,'+w -h -a','a');
         else
            fileattrib(fName,'+w -h -a','','s');
         end
         fid = H5F.open(fName,'H5F_ACC_RDWR','H5P_DEFAULT');
         H5L.delete(fid,'data','H5P_DEFAULT');
         H5F.close(fid);
         obj.diskfile_ = fName; % Associate name at this point
         % Now, create h5 dataset with (correct) desired property list
         if strcmp(obj.type_,'MatFile') % MatFile ~ not extendable
            h5create(fName, varname_, obj.maxdims_h5,...
               'DataType',obj.class_,'FillValue',zeros(1,1,obj.class_));
            
         else % Event, Hybrid
            h5create(fName, varname_, obj.maxdims_h5,...
               'ChunkSize',obj.chunks_h5,'DataType',obj.class_,...
               'Deflate',obj.compress_,'FillValue',zeros(1,1,obj.class_));
         end
         % Figure out indexing for writing to HDF5 file
         start = ones(1,obj.rank_h5); % Index in the file to begin writing
         sz = size(data); % Size of variable to write to H5 file
         stride = ones(1,obj.rank_h5); % Stride for "hyperslab" spacing
         
         % % % Write the data provided to constructor to the Diskfile % % %
         h5write(fName,varname_,data,start,sz,stride);
         % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
         
         % Add attributes denoting that data file is non-empty
         obj.Empty = zeros(1,1,'int8');
         % Add attributes relating to nigeLab structure (for this file)
         addFileNameAttributes(obj,fName);
         
         % And parse the data about that file
         obj.bytes_ = obj.getFileSize();
      end
   end
   
   % STATIC,PROTECTED (validators)
   methods (Static,Access=protected)
      % Shortcut to throw improper assignment error
      function throwImproperAssignmentError(type,varargin)
         %THROWIMPROPERASSIGNMENTERROR  Throws error indicating file cannot
         %                       be written for one reason or another
         %
         %  nigeLab.libs.DiskData.throwImproperAssignmentError(type);
         %
         %  type : (char array; default: 'standard')
         %  --> Throw different error depending on value of `type`
         %  --> Only 'standard' actually causes a matlab error to occur,
         %        which has the identifier:
         %           'nigeLab:DiskData:PermissionDenied'
         
         if nargin < 1
            type = 'standard';
         end
         
         dbstack();
         switch lower(type)
            case {'standard','locked','permission'}
               nigeLab.utils.cprintf('Keywords','For reference:\n'); ...
               ulck_str = nigeLab.utils.getNigeLink(...
                  'nigeLab.libs.DiskData','unlockData','unlockData');
               lck_str = nigeLab.utils.getNigeLink(...
                  'nigeLab.libs.DiskData','lockData','lockData');
               fprintf(1,'-->\t%s\n-->\t%s\n',ulck_str,lck_str);
               error('nigeLab:DiskData:PermissionDenied',...
                  '\n\t\t->\t[DISKDATA]: DiskData object is read-only\n');
            case 'matfile'
               nigeLab.sounds.play('pop',0.35);
               nigeLab.utils.cprintf('Errors*','\t\t->\t[DISKDATA]: '); 
               nigeLab.utils.cprintf('Errors','Cannot append to '); 
               nigeLab.utils.cprintf('Keywords*','''%s''',type);
               nigeLab.utils.cprintf('Errors',' DiskData.type_\n');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
                  '\t\t\t->\t(DiskData.type_ must be ');
               nigeLab.utils.cprintf('Keywords*','''Hybrid''');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',' or '); 
               nigeLab.utils.cprintf('Keywords*','''Event''');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',')\n');
            case 'class'
               nigeLab.sounds.play('pop',0.40);
               nigeLab.utils.cprintf('Errors*','\t\t->\t[DISKDATA]: ');
               nigeLab.utils.cprintf('Errors','Improper assignment.\n');
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
                  '\t\t\t->\t(DiskData is class: '); ...
               nigeLab.utils.cprintf('Keywords*','''%s''',varargin{1});
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
                  ', but data is class: '); 
               nigeLab.utils.cprintf('Keywords*','''%s''',varargin{2});
               nigeLab.utils.cprintf('[0.55 0.55 0.55]','.\n');
            otherwise
               nigeLab.sounds.play('pop',0.45);
               nigeLab.utils.cprintf('Errors*','\t\t->\t[DISKDATA]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Assignment canceled: DiskData object is ');
               nigeLab.utils.cprintf('Keywords*','%s',type);
               nigeLab.utils.cprintf('Errors','.\n');
         end
      end
      
      % Validate size of data from full size of file
      function validateEventDataRange(b,validFunHandle)
         % VALIDATEEVENTDATARANGE  Ensures that 'propName' data is in range
         %
         %  nigeLab.libs.DiskData.validateEventDataRange(b,validFunHandle);
         %
         %  b : Data to assign to an 'Event' type file
         %  validFunHandle : Validator for data in b
         
         if nargin < 2
            % Then nothing to validate
            return;
         end
         
         if iscell(validFunHandle)
            for i = 1:numel(validFunHandle)
               nigeLab.libs.validateEventDataRange(b,validFunHandle{i});
            end
            return;
         end
         
         p = inputParser;
         addRequired(p,'b',validFunHandle);
         parse(p,b);
      end
      
      % Validate size of data for a particular event property
      function validateEventDataSize(b,M,propName)
         % VALIDATEEVENTDATASIZE  Ensures that 'propName' data size is good
         %
         %  nigeLab.libs.DiskData.validateEventDataSize(b,M,propName);
         %
         %  b : 
         %  Assignment data that is to be validated
         %
         %  M : 
         %  Column size of b that is expected
         %  --> If not specified, default value is 1
         %  --> If given as NaN, then there are no size requirements
         %
         %  propName : 
         %  Name of property to be assigned the data in `b`
         %  --> Just used for the error part, not necessary for function
         %  --> By default, set to 'data'
         
         if nargin < 3
            propName = 'data';
         end
         
         if nargin < 2
            M = 1;
         elseif isnan(M)
            % Then no requirements on size: return
            return;
         end
         m = size(b,2);
         if m ~= M
            error(['nigeLab:' mfilename ':BadSize'],...
               ['Input data number of columns (%d) ' ...
               'does not match for %s (%g)\n'],...
               m,upper(propName),M);
         end

      end
   end
   
   % STATIC
   methods (Static)
      % Enumeration to get Column index based on '.' indexing for 'Event'
      function iCol = getEnumeratedColumn(propName,numColumns)
         %GETENUMERATEDCOLUMN  Returns "enumerated" column index for Event
         %
         %  iCol = nigeLab.libs.DiskData.getEnumeratedColumn(propName);
         %  iCol = nigeLab...(propName,dataSize);
         %
         %  propName : char array (e.g. 'ts' or 'value')
         %  numColumns : (optional) Scalar; number of columns in data (fixed
         %                          dimension for 'Event' type)
         
         if nargin < 2
            numColumns = 5; % Minimum number of 'Event' type columns
         end
         
         switch lower(propName)
            case {'data','all'} % All columns
               iCol = numColumns;
            case 'type' % First column
               iCol = 1;
            case {'value','group','index','ind','idx',... % Second column
                  'clus','cluster','clusters','id'} 
               iCol = 2;
            case {'tag','label','mask'} % Third column
               iCol = 3;
            case {'ts','t','time','times','timestamps'} % Fourth column
               iCol = 4;
            case {'snippet','snip','snips','wave','waveform','waves','feat','features',...
                  'x','rate','aligned','lfp','meta','metadata'} % 5th : End columns
               iCol = 5:numColumns;
            otherwise
               error(['nigeLab:' mfilename ':BadSubscriptType'],...
                  '%s not supported by Events type.',propName);
         end
      end
      
      % Parses Column indexing based on data size and offset
      function iCol = parseColumnIndices(S)
         % PARSECOLUMNINDICES  Get column indexes based on substruct S
         %
         %  iCol = nigeLab.libs.DiskData.parseColumnIndices(S);
         %
         %  inputs: 
         %  S  --  Struct element (scalar) from substruct function
         
         if numel(S.subs) > 1
            iCol = S.subs{2};
         else
            iCol = S.subs{1};
         end
         if ischar(iCol)
            switch iCol
               case ':'
                  iCol = inf;
               case 'end'
                  iCol = obj.size_(2);
            end
         end
      end
      
      % Parses Row and Column indexing based on data size and offset
      function [iRow,iCol] = parseRowColumnIndices(S,dataSize,colOffset)
         % PARSEROWCOLUMNINDICES  Get row and column indexes based on
         %                        subsasgn struct S
         %
         %  [iRow,iCol] = nigeLab.libs.DiskData.parseRowColumnIndices(...
         %                 S,dataSize,colOffset);
         %
         %  inputs: 
         %  S  --  Struct from substruct function
         %  dataSize  --  Size of data saved on disk
         %  colOffset  --  (Optional) For example, for 'snippet' this might
         %                    be set to 4 to account for the fact that the
         %                    first 4 columns are removed.
         
         if nargin < 3
            colOffset = 0;
         end
         
         if islogical(S.subs{1})
            S.subs{1} = find(S.subs{1});
         end
         
         if isnumeric(S.subs{1})
            iRow = S.subs{1};
         elseif strcmpi(S.subs{1},':')
            iRow = 1:dataSize(1);
         elseif strcmpi(S.subs{1},'end')
            iRow = dataSize(1);
         end
         if numel(S.subs) > 1
            if islogical(S.subs{2})
               S.subs{2} = find(S.subs{2});
            end
            
            if isnumeric(S.subs{2})
               iCol = S.subs{2};
            elseif strcmpi(S.subs{2},':')
               iCol = 1:(dataSize(2) + colOffset);
            elseif strcmpi(S.subs{2},'end')
               iCol = dataSize(2) + colOffset;
            end
         else 
            iCol = 1 + colOffset;
         end
      end
      
      % List valid attribute names
      function [VALID,DEF] = validAttributeList()
         %VALIDATTRIBUTELIST  Return list of valid attributes (cell array)
         %
         %  VALID = nigeLab.libs.DiskData.validAttributeList()
         %  --> VALID: Cell array of valid attributes
         %
         %
         %  [VALID,DEF] = nigeLab.libs.DiskData.validAttributeList()
         %  --> DEF: Cell array of default attribute values
         %
         %  Current Attributes List:
         %  * 'Index'  --  1: Current "data cursor" index in file
         %  * 'Complete'  --  True: Data has been extracted to file
         %  * 'Empty'  --  True: file data contents are empty
         %  * 'Locked'  --  True: file is "locked" (read-only)
         %  * 'Block'  --  char array: Name of recording block
         %  * 'Animal'  --  char array: Name of animal (parent)
         %  * 'Tank'  --  char array: Name of tank (parent of parent)
         
         VALID = {'Index',...
            'Complete','Empty','Locked',...
            'Block','Animal','Tank'};
         DEF = {double.empty,...
            int8.empty,int8.empty,int8.empty,...
            char.empty,char.empty,char.empty};
      end
   end
   % % % % % % % % % % END METHODS% % %
end

