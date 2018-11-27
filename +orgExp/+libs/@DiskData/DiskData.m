classdef DiskData
    %DISKDATA
    
    properties (Access = private)
        diskfile_
        type_
        name_
        size_
        bytes_
        class_
        chunks_
    end
    
    methods
        function obj = DiskData(varargin)
            %% DISKDATA Constructor
            % D = DiskData(MatFile)
            % ----------------------------------            
            % D = DiskData(Datatype_,DataPath,Data)
            % D = DiskData(Datatype_,DataPath)
            % 
            % varargin 
            %               name
            %               size
            %               class
            
            
            %%input parsing 
            tmp={'name','size','class'};
            nargin=numel(varargin);
            jj=nargin+1;
            for ii=1:nargin
                if ~isempty(find(strcmp(varargin(ii),tmp),1))
                    jj=ii;
                    break;
                end
            end
            for iV = jj:2:nargin
                eval(sprintf([lower(varargin{iV}), '_=varargin{iV+1};']));
            end
            nargin=jj-1;
            switch nargin
                case 2
                    size_=[1 inf];
                    name_='data';
                    chunks_=[1 2048];
                    class_ = 'double';
                case 3
                    size_=[1 inf];
                    name_='data';
                    class_=class(varargin{3});
                    chunks_=[1 2048];
            end
            %% creating files
            switch nargin
                case 1
                    if isa(varargin{1},'matlab.io.MatFile')
                        obj.diskfile_ = varargin{1};
                        info = whos(obj.diskfile_);
                        obj.type_='MatFile';
                        obj.name_ = info.name;
                    else
                        error('Data format not yet supported');
                    end
                case 2
                    switch varargin{1}
                        case 'MatFile'
                            data=zeros(1,1,class_);
                            if ~exist(varargin{2},'file')
                                data=ones(1,1,class_);
                                save(varargin{2},name_,'-v7.3');
                            end
                            obj.diskfile_ = matfile(varargin{2},...
                                'Writable',true);
                            obj.type_='MatFile';
                            obj.name_ = name_;
                            obj.size_ = [0 0];
                            obj.bytes_ = 0;
                            obj.class_ = class_;
                            if data
                                fid = H5F.open(varargin{2},'H5F_ACC_RDWR','H5P_DEFAULT');
                                H5L.delete(fid,'data','H5P_DEFAULT');
                                H5F.close(fid);
                                varname_ = ['/' obj.name_];
                                h5create(varargin{2}, varname_, size_,'ChunkSize',chunks_,'DataType',class_);
                            end
                           
                        otherwise
                            error('Unknown data format');
                    end
                case 3
                    switch varargin{1}
                        case 'MatFile'
                            obj.diskfile_ = matfile(varargin{2},...
                                'Writable',true);
                            varname_ = ['/' name_];
                            h5create(varargin{2}, varname_, size_,'ChunkSize',chunks_,'DataType',class_);
                            h5write(varargin{2}, '/data', varargin{3},[1 1],size(varargin{3}));
                            info = whos(obj.diskfile_);
                            obj.type_='MatFile';
                            obj.name_ = info.name;
                            obj.size_ = info.size;
                            obj.bytes_ = info.bytes;
                            obj.class_ = info.class;
                        otherwise
                            error('Unknown data format');
                    end
                otherwise
                    error('Wrong number of input parameter');
            end
        end        
        
        function varargout = subsref(obj,S)
%             Out=obj.diskfile_.(obj.name_);
            Out = 'obj';
            for ii=1:numel(S)
                switch S(ii).type
                    case '()'
                        if ii==1 && ~strcmp(class(obj),'struct')
                                                        
                            nArgs=numel(S(ii).subs);
                            if nArgs==1
                                [~,I]=max(size(obj));
                                tmp=S(ii).subs{1};
                                S(ii).subs(1:numel(size(obj)))={1};
                                S(ii).subs{I}=tmp;
                            end
                            SizeCheck=cellfun( @(x) max(x), S(ii).subs )>obj.size;
                            
                            if any(SizeCheck(~any(strcmp(S(ii).subs,':'))))
                                error('Index exceeds matrix dimension.');
                            end
                                                   
                            if cellfun( @(x) any(diff(x)-1), S(ii).subs(2))
                                indx = [1  cellfun( @(x) find(diff(x)-1), S(ii).subs(2))+1;
                                    cellfun( @(x) find(diff(x)-1), S(ii).subs(2)) numel(S(ii).subs{2})];
                            elseif any(strcmp(S(ii).subs,':'))
                                indx = [ 1; inf];
                            else
                                indx=[S(ii).subs{2}(1) S(ii).subs{2}(end)-S(ii).subs{2}(1)];
                            end
                            Out = [];
                            varname=['/' obj.name_];
                            for kk=1:size(indx,2)
                                Out=[Out h5read(obj.getPath,varname,[1 indx(1,kk)],[1 indx(2,kk)])];                                
                            end
                            varargout(1) = {Out};
                            return;
                        elseif ii==1 && strcmp(class(obj),'struct')
                            Out='obj.diskfile_.(obj.name_)';
                            Out = sprintf('%s(S(ii).subs{:})',Out);
                        else
                             Out = sprintf('%s(S(ii).subs{:})',Out);
                        end
                    case '{}'
                        warning('curly indexing not supported yet')
                    case '.'
                        s=methods(obj);
                        if any(strcmp(s,S(ii).subs))
                            Out = sprintf('obj.%s',S(ii).subs);
                        else
                            Out = sprintf('%s.(%s)',Out,S(ii).subs);
                        end
                end
            end
            Out = eval(Out);
            varargout(1) = {Out};
        end
        
         function obj = subsasgn(obj,S,b)
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
                             tmp(S.subs{:})=b;
                         end
                         
                     case '.'
                         tmp.(S.subs{:}) = b;
                         
                     case '{}'
                 end
             end
             obj.diskfile_.(obj.name_) = tmp;
        end
        
        function ind = end(obj,k,n)
            szd = size(obj);
            if k < n
                ind = szd(k);
            else
                ind = prod(szd(k:end));
            end
        end
        
        function Out = minus(obj,b)
            if isa(b,'orgExp.libs.DiskData')
                Out=obj.diskfile_.(obj.name_)(:,:)-b.diskfile_.(b.name_)(:,:);
            elseif isnumeric(b)
                Out=obj.diskfile_.(obj.name_)(:,:)-b;
            end
        end
        
        function Out = plus(obj,b)
            if isa(b,'orgExp.libs.DiskData')
                Out=obj.diskfile_.(obj.name_)(:,:)+b.diskfile_.(b.name_)(:,:);
            elseif isnumeric(b)
                Out=obj.diskfile_.(obj.name_)(:,:)+b;
            end
        end
        
        function Out = times(obj,b)
            Out=obj.diskfile_.(obj.name_)(:,:).*b;
        end
            
        function Out = mtimes(obj,b)
            if isa(b,'orgExp.libs.DiskData')
                Out=obj.diskfile_.(obj.name_)(:,:)*b.diskfile_.(b.name_)(:,:);
            elseif isnumeric(b)
                Out=obj.diskfile_.(obj.name_)(:,:)*b;
            end
        end
        
        function dim = size(obj,n)
            info = whos(obj.diskfile_);
            if length(info)~=1
                [~,I]=max([info.bytes_]);
                info=info(I);
            end
            if nargin<2
                n=1:length(info.size);
            end
            dim=info.size(n);
        end
        
        function cl=class(obj)
            cl = obj.class_;
        end
        
        function l=length(obj)
            info = whos(obj.diskfile_);
            l=max(info.size);
        end
        
        function Out = double(obj)
            Out= double(obj.diskfile_.(obj.name_)(:,:));
        end
        
        function Out = single(obj)
            Out= single(obj.diskfile_.(obj.name_)(:,:));
        end
        
        function Out = getPath(obj)
            Out=obj.diskfile_.Properties.Source;
        end
        
        function Out = append(obj,b)
            Out = obj;
            varname_ = ['/' obj.name_];
            h5write(obj.getPath, varname_, b(1,:),[1,(obj.size(2)+1)],size(b));
            if not(strcmp(class(obj),class(b))|isa(b,'orgExp.libs.DiskData'))
                error('Cannot concatenate objects of different classes');
            end
                 Out.size_= size(obj)+size(b);      
        end
        
        function disp(obj)
            switch obj.type_
                case 'MatFile'
                    disp(obj.diskfile_.(obj.name_));
                case 'HDF5'
                    fname=obj.diskfile_.Filename;
                    disp(hdf5read(fname,obj.name_));
            end
        end
        
        function x=abs(obj)
            x = abs(obj.diskfile_.(obj.name_));
        end
        
        function b = isempty(obj)
            b = isempty(obj.diskfile_.(obj.name_));
        end
        
    end
end

