classdef DiskData < handle
   %% DISKDATA   Class to efficiently handle data without loading to RAM
   %
   %  D = DiskData(MatFile)
   %  D = DiskData(Datatype_,DataPath)
   %  D = DiskData(Datatype_,DataPath,Data)
   %  D = DiskData(___,'name',value,...)
   %
   %  --------
   %   INPUTS
   %  --------
   %  MatFile     :     Class matlab.io.MatFile object that points to data
   %                       saved on the disk.
   %
   %    ---
   %
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
   %     DiskData - Class constructor.
   %
   % By: MAECI 2018 collaboration (Federico Barban & Max Murphy)
   properties (GetAccess = public, SetAccess = private)
      type     % Event type
      value    % Value associated with event (e.g. spike cluster class)
      tag      % Tag associated with event (e.g. spike cluster label)
      ts       % Time of event (seconds)
      snippet  % Values around the event
      data     % Values stored in 'Hybrid' and 'MatFile' format
   end
   
   properties (SetAccess = private, GetAccess = private)
      diskfile_   % Contains actual 'MatFile'
      type_       % 'MatFile' (only MatFile) or 'Hybrid' (combo H5 stuff) or 'Event' (spikes etc)
      name_       % Name of variable pointed to by DiskData array
      size_       % Size (dimensions) of DiskData array
      bytes_            % Number of bytes in DiskData
      class_            % Class of data pointed to by DiskData array
      chunks_           % Size of "chunks" to read
      access_           % Access type
      writable_         % Whether file is writable
   end
   
   methods
      function obj = DiskData(varargin)
         %% DISKDATA   Constructor
         %
         %  D = DiskData(MatFile)
         %  D = DiskData(Datatype_,DataPath)
         %  D = DiskData(Datatype_,DataPath,Data)
         %
         %  --------
         %   INPUTS
         %  --------
         %  MatFile     :     Class matlab.io.MatFile object that points to
         %                       data saved on the disk.
         %
         %    ---
         %
         %  Datatype_   :     If 2 arguments are specified, the first
         %                       argument becomes Datatype_, which is
         %                       either 'MatFile' or 'Hybrid' currently
         %                       (string). This must be specified in
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
         %
         % By: MAECI 2018 collaboration (Federico Barban & Max Murphy)
         
         
         %% PARSE INPUTS
         tmp={'name','size','class','access'};
         nargin=numel(varargin);
         
         % Get the index where to start parsing "variable" part of varargin
         jj=nargin+1;
         for ii=1:nargin
            if ~isempty(find(strcmp(varargin(ii),tmp),1))
               jj=ii;
               break;
            end
         end
         
         % "Non-variable" elements indicate the total number of "default"
         % input arguments. Parse object properties from those elements.
         %
         % note: This could also be achieved by specifying the input
         %       argument names, but then to access the "variable" inputs
         %       you would have to provide dummy inputs to the first 3
         %       input arguments. The tradeoff is that doing it this way,
         %       you don't get the tooltip for what each variable name is
         %       when opening DiskData. That is probably fine, since it is
         %       more of an "under the hood" class, so I think it's good as
         %       is. -MM
         nargin=jj-1;
         switch nargin
            case 2
               size_=[1 inf];
               name_='data';
               chunks_=[1 2048];
               class_ = 'double';
               access_ = 'r';
            case 3
               size_=size(varargin{3});
               name_='data';
               class_=class(varargin{3});
               chunks_=[1 2048];
               access_ = 'r';
         end
         
         %% PARSE VARARGIN
         % "Variable" part of varargin allows setting of "non-default"
         % input arguments.
         for iV = jj:2:numel(varargin)
            eval(sprintf([lower(varargin{iV}), '_=varargin{iV+1};']));
         end
         writable_ = strcmpi(access_,'w');
         
         %% CREATE DIFFERENT TYPES OF DISKDATA FOR DIFFERENT FILE TYPES
         switch nargin
            case 1 % Only 1 "default" input provided
               % This case is specifically for dealing with MatFiles.
               if isa(varargin{1},'matlab.io.MatFile')
                  obj.diskfile_ = varargin{1};
                  info = whos(obj.diskfile_);
                  obj.type_='MatFile';
                  obj.name_ = info.name;
                  obj.writable_ = isWritable(obj.diskfile_);
                  if obj.writable_
                     obj.access_ = 'w';
                  else
                     obj.access_ = 'r';
                  end
               else
                  error('Data format not yet supported');
               end
            case 2 % 2 "default" inputs provided: file type and file name
               fType = varargin{1}; % First arg is the file type
               fName = varargin{2}; % Second arg is the file name
               if writable_
                  obj = unlockData(obj);
               else
                  obj = lockData(obj);
               end
               switch fType
                  case 'MatFile' % Can deal with MatFiles
                     % This allows instantiation of the variable to be
                     % loaded from the MatFile. All the large data streams
                     % are saved with 'data' as the name of the long
                     % variable. However, some files may have a different
                     % name for the variable that you wish to access, such
                     % as 'spikes' or 'features' in the SPIKES file.
                     eval(sprintf('%s=zeros(1,1,class_);',name_));
                     if exist(fName,'file') % If it exists
                        obj.diskfile_ = matfile(fName,... % point to it
                           'Writable',obj.writable_);
                        info = whos(obj.diskfile_);
                        if isscalar(info)
                           data=load(fName);
                           info = whos(data);
                        end
                        % And parse information about the file itself
                        obj.bytes_ = info.bytes;
                        obj.name_ = info.name;
                        obj.size_ = info.size;
                        obj.class_ = info.class;
                     else % otherwise it has not been created on disk
                        eval(sprintf('%s=ones(1,1,class_);',name_));
                        % so save it
                        save(fName,name_,'-v7.3');
                        % point to it
                        obj.diskfile_ = matfile(fName,...
                           'Writable',obj.writable_);
                        % and initialize information about the file
                        obj.name_ = name_;
                        obj.size_ = [0 0];
                        obj.bytes_ = 0;
                        obj.class_ = class_;
                     end
                     obj.type_='MatFile';
                     
                  case 'Hybrid' % Deals with both MatFile and HDF5-ish ?
                     % The default name is 'data'
                     eval(sprintf('%s=zeros(1,1,class_);',name_)); % start with a small vector
                     if ~exist(fName,'file')
                        eval(sprintf('%s=ones(1,1,class_);',name_));
                        save(fName,name_,'-v7.3');
                        obj.name_ = name_;
                        obj.size_ = [0 0];
                        obj.bytes_ = 0;
                        obj.class_ = class_;
                        obj.diskfile_ = matfile(fName,...
                           'Writable',obj.writable_);
                     else
                        obj.diskfile_ = matfile(fName,...
                           'Writable',obj.writable_);
                        info = whos(obj.diskfile_);
                        [~,I]=max(cat(1,info(:).size),[],1);
                        I=unique(I);
                        % If the file already exists, and it is not a
                        % column vector, then you might have accessed a
                        % weird file like the SPIKES file etc. that have
                        % snippet matrices. Check for this:
                        if size(I,2)~=1
                           error(['Your file looks weird (%d max elements).\n' ...
                              'I wasn''t able to properly connect it to DiskData.'],size(I,2));
                        end
                        obj.bytes_ = info(I).bytes;
                        obj.name_ = info(I).name;
                        obj.size_ = info(I).size;
                        obj.class_ = info(I).class;
                     end
                     obj.type_='Hybrid';
                     
                     if data % If data has been found, do some H5 handling
                        fid = H5F.open(varargin{2},'H5F_ACC_RDWR','H5P_DEFAULT');
                        H5L.delete(fid,'data','H5P_DEFAULT');
                        H5F.close(fid);
                        varname_ = ['/' obj.name_];
                        h5create(varargin{2}, varname_, size_,'ChunkSize',chunks_,'DataType',class_);
                     end
                     
                  case 'Event' % Deal with Spikes and other Events
                     % The default name is 'data'
                     obj.class_ = 'double';
                     data = zeros(1,5,obj.class_);
                     if ~exist(fName,'file')
                        data=ones(1,5,obj.class_);
                        
                        save(fName,name_,'-v7.3');
                        obj.name_ = name_;
                        obj.size_ = [0 0];
                        obj.bytes_ = 0;
                        obj.class_ = class_;
                        obj.diskfile_ = matfile(fName,...
                           'Writable',obj.writable_);
                     else
                        obj.diskfile_ = matfile(fName,...
                           'Writable',obj.writable_);
                        info = whos(obj.diskfile_);
                        [~,I]=max(cat(1,info(:).size),[],1);
                        I=unique(I);
                        % If the file already exists, and it is not a
                        % column vector, then you might have accessed a
                        % weird file like the SPIKES file etc. that have
                        % snippet matrices. Check for this:
                        if size(I,2)~=1
                           error(['Your file looks weird (%d max elements).\n' ...
                              'I wasn''t able to properly connect it to DiskData.'],size(I,2));
                        end
                        obj.bytes_ = info(I).bytes;
                        obj.name_ = info(I).name;
                        obj.size_ = info(I).size;
                        obj.class_ = info(I).class;
                     end
                     obj.type_='Event';
                     
                     if data % If data has been found, do some H5 handling
                        fid = H5F.open(varargin{2},'H5F_ACC_RDWR','H5P_DEFAULT');
                        H5L.delete(fid,'data','H5P_DEFAULT');
                        H5F.close(fid);
                        varname_ = ['/' obj.name_];
                        h5create(varargin{2}, varname_, size_,'ChunkSize',chunks_,'DataType',class_);
                     end
                     
                  otherwise
                     error('Unknown data format');
               end
            case 3 % In this case, the data was included in constructor
               fType = varargin{1}; % First arg is the file type
               fName = varargin{2}; % Second arg is the file name
               % Third arg is the data; don't make a copy of that
               if writable_
                  obj = unlockData(obj);
               else
                  obj = lockData(obj);
               end
               switch fType
                  case 'MatFile'
                     eval(sprintf('%s=varargin{3};',name_));
                     % Depending on how the file was saved
                     if isstruct(varargin{3})
                        save(fName,'-struct',name_,'-v7.3');
                     else
                        save(fName,name_,'-v7.3');
                     end
                     obj.diskfile_ = matfile(fName,...
                        'Writable',obj.writable_);
                     obj.diskfile_.(name_) = varargin{3};
                     obj.type_='MatFile';
                     obj.name_ = name_;
                     obj.size_ = size_;
                     obj.class_ = class_;
                     info = whos(obj.diskfile_);
                     obj.bytes_ = info.bytes;
                  case 'Hybrid'
                     % This initially creates a file with a variable,
                     % 'data', that is written to it.
                     data=zeros(1,1,class_);
                     save(fName,'data','-v7.3');
                     
                     % Now that the file exists, make a matfile pointing to
                     % it, and then append the data structure in
                     % varargin{3} to that file on the disk.
                     obj.diskfile_ = matfile(fName,...
                        'Writable',obj.writable_);
                     
                     obj.type_='Hybrid';
                     obj.name_ = name_;
                     obj.size_ = size_;
                     obj.class_ = class_;
                     fid = H5F.open(fName,'H5F_ACC_RDWR','H5P_DEFAULT');
                     H5L.delete(fid,'data','H5P_DEFAULT');
                     H5F.close(fid);
                     varname_ = ['/' obj.name_];
                     h5create(fName, varname_, size_,'DataType',class_);
                     
                     h5write(fName, '/data', varargin{3},[1 1],size(varargin{3}));
                     
                     % And parse the data about that file
                     info = whos(obj.diskfile_);
                     obj.bytes_ = info.bytes;
                  case 'Event'
                     % This initially creates a file with a variable,
                     % 'data', that is written to it.
                     data=zeros(1,1,class_);
                     save(fName,'data','-v7.3');
                     
                     % Now that the file exists, make a matfile pointing to
                     % it, and then append the data structure in
                     % varargin{3} to that file on the disk.
                     obj.diskfile_ = matfile(fName,...
                        'Writable',obj.writable_);
                     
                     obj.type_='Event';
                     obj.name_ = name_;
                     obj.class_ = class_;
                     fid = H5F.open(fName,'H5F_ACC_RDWR','H5P_DEFAULT');
                     H5L.delete(fid,'data','H5P_DEFAULT');
                     H5F.close(fid);
                     varname_ = ['/' obj.name_];
                     h5create(fName, varname_, size_,'DataType',class_);
                     
                     h5write(fName, '/data', varargin{3},[1 1],size(varargin{3}));
                     
                     % And parse the data about that file
                     info = whos(obj.diskfile_);
                     obj.bytes_ = info.bytes;
                     
                     % For some reason need to get size information this
                     % way, seems redundant not sure why?
                     data = obj.diskfile_.(obj.name_);
                     obj.size_ = size(data);
                  otherwise
                     error('Unknown data format');
               end
            otherwise
               error('Wrong number of input parameter');
         end
      end
      
      function varargout = subsref(obj,S)
         %% SUBSREF  Overloaded function for referencing DiskData array
         Out = 'obj';
         readDat=true;
         
         switch obj.type_
            case 'Event'
               switch S(1).type
                  case '()'
                     
                     if any(strcmp(S(1).subs,':'))
                        indx = [1 inf];
                        
                     else
                        if islogical(S(1).subs{1})
                           S(1).subs{1} = find(S(1).subs{1});
                           S(1).subs{1} = reshape(S(1).subs{1},...
                              1,numel(S(1).subs{1}));
                        end
                        if isempty(S(1).subs{1})
                           varargout = {[]};
                           return;
                        end
                        interindx=find(diff(S(1).subs{1})-1);
                        indx=0;
                        for nn=1:numel(interindx)
                           indx=[indx (interindx(nn)) (interindx(nn))]; %#ok<AGROW>
                        end
                        indx=reshape([indx numel(S(1).subs{1})],2,[])'+[1 0];
                        indx=S(1).subs{1}(indx);
                     end
                     indx=horzcat(indx(:,1), diff(indx,[],2)+1);
                     N = sum(indx(:,2));
                     if isinf(N)
                        N = obj.size_(1);
                        indx(end,2) = N;
                     end
                     data = nan(N,obj.size_(2)); %#ok<*PROPLC>
                     ii = 1;
                     for kk=1:size(indx,1)
                        vec = ii:(ii+indx(kk,2)-1);
                        data(vec,:) = h5read(obj.getPath,'/data',...
                           [indx(kk,1),1],[indx(kk,2),obj.size_(2)]);
                        ii = ii + indx(kk,2);
                     end
                     varargout = {...
                        data(:,1), ...    % "type"
                        data(:,2), ...    % "value"
                        data(:,3), ...    % "tag"
                        data(:,4), ...    % "ts"
                        data(:,5:end)};   % "snippet"
                     
                     
                     return;
                     
                  case '.'
                     if numel(S) > 1
                        if islogical(S(2).subs{1})
                           S(2).subs{1} = find(S(2).subs{1});
                           S(2).subs{1} = reshape(S(2).subs{1},...
                              1,numel(S(2).subs{1}));
                        end
                        if isempty(S(2).subs{1})
                           varargout = {[]};
                           return;
                        end
                        interindx=find(diff(S(2).subs{1})-1);
                        indx=0;
                        for nn=1:numel(interindx)
                           indx=[indx (interindx(nn)) (interindx(nn))]; %#ok<AGROW>
                        end
                        indx=reshape([indx numel(S(2).subs{1})],2,[])'+[1 0];
                        indx=S(2).subs{1}(indx);
                     else
                        indx = [1 inf];
                     end
                     
                     indx=horzcat(indx(:,1),diff(indx,[],2)+1);
                     N = sum(indx(:,2));
                     if isinf(N)
                        if obj.size_(1) == 0
                           obj.checkSize;
                        end
                        N = obj.size_(1);
                        indx(end,2) = N;
                     end

                     data = nan(N,obj.size_(2));
                     ii = 1;
                     for kk=1:size(indx,1)
                        vec = ii:(ii+indx(kk,2)-1);
                        data(vec,:) = h5read(obj.getPath,'/data',...
                           [indx(kk,1),1],[indx(kk,2),obj.size_(2)]);
                        ii = ii + indx(kk,2);
                     end
                     switch lower(S(1).subs)
                        case 'type'
                           varargout = {data(:,1)};
                        case 'value'
                           varargout = {data(:,2)};
                        case 'tag'
                           varargout = {data(:,3)};
                        case 'ts'
                           varargout = {data(:,4)};
                        case 'snippet'
                           varargout = {data(:,5:end)};
                        otherwise
                           error('%s is not supported for Events type.',...
                              lower(S(1).subs));
                     end
                     return;
               end
               
               
            otherwise
               
               for ii=1:numel(S)
                  switch S(ii).type
                     case '()'
                        nArgs=numel(S(ii).subs);
                        if nArgs==1
                           if ~exist('sz','var'),sz=size(obj);end
                           [~,I]=max(sz);
                           tmp=S(ii).subs{1};
                           S(ii).subs(1:numel(size(obj)))={1};
                           S(ii).subs{I}=tmp;
                        end
                        SizeCheck=cellfun( @(x) max(x), S(ii).subs )>obj.size;
                        
                        if any(SizeCheck(~any(strcmp(S(ii).subs,':'))))
                           error('Index exceeds matrix dimension.');
                        end
                        if readDat && strcmp(obj.type_,'Hybrid')
                           %                             if cellfun( @(x) any(diff(x)-1), S(ii).subs(2))
                           if any(strcmp(S(ii).subs,':'))
                              indx = [1 inf];
                           else
                              % Add handling for logical indexing
                              if islogical(S(ii).subs{2})
                                 S(ii).subs{2} = find(S(ii).subs{2});
                                 S(ii).subs{2} = reshape(S(ii).subs{2},...
                                    1,numel(S(ii).subs{2}));
                              end
                              if isempty(S(ii).subs{2})
                                 varargout = {[]};
                                 return;
                              end
                              interindx=find(diff(S(ii).subs{2})-1);
                              indx=0;
                              for nn=1:numel(interindx)
                                 indx=[indx (interindx(nn)) (interindx(nn))];
                              end
                              indx=reshape([indx numel(S(ii).subs{2})],2,[])'+[1 0];
                              indx=S(ii).subs{2}(indx);
                           end
                           indx=horzcat(indx(:,1), diff(indx,[],2)+1);
                           Out = [];
                           varname=['/' obj.name_];
                           for kk=1:size(indx,1)
                              Out=[Out h5read(obj.getPath,varname,[1 indx(kk,1)],[1 indx(kk,2)])];
                           end
                           varargout(1) = {Out};
                           return;
                        elseif readDat && strcmp(obj.type_,'MatFile')
                           Out = sprintf('%s(S(%d).subs{:})',Out,ii);
                        else
                           Out = sprintf('%s(S(%d).subs{:})',Out,ii);
                        end
                        readDat=false;
                     case '{}'
                        warning('curly indexing not supported yet')
                     case '.'
                        s=methods(obj);
                        if any(strcmp(s,S(ii).subs)) && ~strcmp('class',S(ii).subs) % to enforce backwards compatibility where some spike structure saved in the past has a class field
                           Out = builtin('subsref',obj,S);
                           varargout(1) = {Out};
                           return;
                           %                             Out = sprintf('obj.%s',S(ii).subs);
                        else
                           readDat = true;
                           sz = size(obj.diskfile_.(S(ii).subs));
                           Out = sprintf('obj.diskfile_.%s',S(ii).subs);
                        end
                  end
               end
         end
         Out = eval(Out);
         varargout(1) = {Out};
      end
      
      function obj = subsasgn(obj,S,b)
         %% SUBSASGN    Overloaded function for DiskData array assignment
         if ~obj.writable_
            error('Improper assignment. DiskData object constructed as read-only.');
         end
         
         tmp = obj.diskfile_.(obj.name_);
         for ii=1:numel(S)
            switch S(ii).type
               case '()'
                  nArgs=numel(S(ii).subs);
                  if nArgs==1
                     [~,I]=max(size(obj));
                     tmp_=S(ii).subs{1};
                     S(ii).subs(1:numel(size(obj)))={1};
                     S(ii).subs{I}=tmp_;
                     clear('tmp_');
                  end
                  if isempty(tmp)
                     clear('tmp');
                     tmp(S(ii).subs{:})=b;
                  else
                     %                      tmp(S.subs{:})=b; % switched -MM
                     tmp(S.subs{1})=b;  % (Federico, this probably isn't
                     %  I just switched it so it will
                     %  temporarily work -MM.)
                  end
                  
               case '.'
                  tmp.(S.subs{:}) = b;
                  
               case '{}'
            end
         end
         obj.diskfile_.(obj.name_) = tmp;
      end
      
      function ind = end(obj,k,n)
         %% END   Overloaded function for indexing end of DiskData array
         szd = size(obj);
         if k < n
            ind = szd(k);
         else
            ind = prod(szd(k:end));
         end
      end
      
      function Out = minus(obj,b)
         %% MINUS    Overloaded function for subtraction on DiskData array
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
      
      function Out = plus(obj,b)
         %% PLUS    Overloaded function for addition on DiskData array
         Out = obj.minus(obj,-b);
      end
      
      function Out = times(obj,b)
         %% TIMES  Overloaded function for multiplication on DiskData array
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
      
      function Out = mtimes(obj,b)
         %% MTIMES  Overloaded function for matrix multiplication
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
      
      function dim = size(obj,n)
         %% SIZE  Overloaded function for getting DiskData array dimensions
         if nargin<2
            n=1:length(obj.size_);
         end
         dim=obj.size_(n);
      end
      
      function l=length(obj)
         %% LENGTH  Overloaded function for getting DiskData array length
         info = whos(obj.diskfile_);
         l=max(info.size);
      end
      
      function Out = double(obj)
         %% DOUBLE Overloaded function for casting DiskData array to double
         varname=[ '/' obj.name_];
         a = h5read(obj.getPath,varname,[1 1],[1 inf]);
         Out= double(a);
      end
      
      function Out = single(obj)
         %% SINGLE Overloaded function for casting DiskData array to single
         varname=[ '/' obj.name_];
         a = h5read(obj.getPath,varname,[1 1],[1 inf]);
         Out= single(a);
      end
      
      function Out = getPath(obj)
         %% GETPATH  Overloaded function for getting path to file
         Out=obj.diskfile_.Properties.Source;
      end
      
      function Out = append(obj,b)
         %% APPEND   Overloaded function for concatenating elements to DiskData array
         if ~obj.writable_
            error('Improper assignment. DiskData object constructed as read-only.');
         end
         Out = obj;
         varname_ = ['/' obj.name_];
         if not(strcmp(obj.class_,class(b)) | isa(b,'nigeLab.libs.DiskData'))
            error('Cannot concatenate objects of different classes');
         end
         h5write(obj.getPath, varname_, b(1,:),[1,(obj.size(2)+1)],size(b));
         Out.size_= size(obj)+size(b);
      end
      
      function Out=disp(obj)
         %% DISP  Overloaded function for printing DiskData elements to command window
         switch obj.type_
            case 'Hybrid'
               if nargout>0
                  Out=[];
               end
               varname=[ '/' obj.name_];
               a = h5read(obj.getPath,varname,[1 1],[1 inf]);
               disp(a);
            case 'MatFile'
               if nargout>0
                  Out=[];
               end
               a = obj.diskfile_.(obj.name_);
               disp(a);
            case 'Event'
               a = obj.diskfile_.(obj.name_);
               fprintf(1,'%g events\n',obj.size_(1));
               str = {'type','value','tag','ts','snippet'};
               for ii = 1:numel(str)
                  if any(a(:,ii)~=0)
                     fprintf(1,'->\t %s contains data.\n',str{ii});
                  else
                     fprintf(1,'--->\t %s contains only zeros.\n',str{ii});
                  end
               end   
               if nargout > 0
                  Out = [];    
               end
            otherwise
               error('Unknown type: %s',obj.type_);
         end
         
      end
      
      function x=abs(obj)
         %% ABS   Overloaded function for getting absolute value of DiskData array
         varname=[ '/' obj.name_];
         a = h5read(obj.getPath,varname,[1 1],[1 inf]);
         x = abs(a);
      end
      
      function b = isempty(obj)
         %% ISEMPTY  Overloaded function for checking if DiskData array contains data
         b = all(size(obj)==0);
      end
      
      function obj = lockData(obj)
         %% LOCKDATA    Method to set write access to read-only
         
         obj.writable_ = false;
         obj.access_ = 'r';
         
      end
      
      function obj = unlockData(obj)
         %% UNLOCKDATA    Method to allow write access
         
         obj.writable_ = true;
         obj.access_ = 'w';
         
      end
      
      function info = getInfo(obj)
         %% GETINFO  Get info about the diskfile
         info = whos(obj.diskfile_);
      end
      
      function cl=class(obj)
         %% CLASS  Overloaded function for getting DiskData array class
         % Note: I changed this to reflect the Matlab class naming
         %       convention that uses the '.' notation. -MM
         cl = sprintf('DiskData.%s', obj.class_);
      end
      
      function checkSize(obj)
         %% CHECKSIZE   Check the size of object if it is a weird value
         a = obj.diskfile_.(obj.name_);
         sz = size(a);
         for ii = 1:numel(obj.size_)
            if obj.size_(ii) ~= sz(ii)
%                warning('Incorrect dimension (%d): %g --> %g (fixed)',...
%                   ii,obj.size_(ii),sz(ii));
               obj.size_(ii) = sz(ii);
            end
         end
         obj.size_ = size(a);
      end
   end
end

