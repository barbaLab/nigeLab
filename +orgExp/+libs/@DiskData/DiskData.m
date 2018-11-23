classdef DiskData
    %DISKDATA
    
    properties (Access = private)
        diskfile_
        type_
        name_
        size_
        bytes_
        class_
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
            for ii=1:nargin
                if ~isempty(find(strcmp(varargin(ii),tmp),1))
                    break;
                end
            end
            nargin=ii-1;
            switch nargin
                case 2
                    size_=inf;
                    name_='data';
                case 3
                    size_=size(varargin{3});
                    name_='data';
                    class_=class(varargin{3});
            end
            for iV = ii:2:nargin
                eval(sprintf([lower(varargin{iV}), '_=varargin{iV+1};']));
            end
            %% creating files
            switch nargin
                case 1
                    if isa(varargin{1},'matlab.io.MatFile')
                        obj.diskfile_ = varargin{1};
                        info = whos(obj.diskfile_);
                        obj.type_='MatFile';
                        obj.name_ = info.name_;
                    else
                        error('Data format not yet supported');
                    end
                case 2
                    switch varargin{1}
                        case 'MatFile'
                            obj.diskfile_ = matfile(varargin{2},...
                                'Writable',true);
                            if ~exist(varargin{2},'file')
                                obj.diskfile_.data = [];
                            end
                            info = whos(obj.diskfile_);
                            obj.type_='MatFile';
                            obj.name_ = info.name_;
                            obj.size_ = info.size;
                            obj.bytes_ = info.bytes_;
                            obj.class_ = info.class;
                            
                        case 'HDF5'
                                varname_ = ['/' name_];
                                h5create(varargin{2}, varname_, size_);
                                obj.type_='HDF5';
                        otherwise
                            error('Unknown data format');
                    end
                case 3
                    switch varargin{1}
                        case 'MatFile'
                            data=0;
                            save(fullfile(varargin{2}),'data','-v7.3');
                            obj.diskfile_ = matfile(varargin{2},...
                                'Writable',true);
                            obj.diskfile_.data = varargin{3};
                            info = whos(obj.diskfile_);
                            obj.type_='MatFile';
                            obj.name_ = info.name;
                            obj.size_ = info.size;
                            obj.bytes_ = info.bytes;
                            obj.class_ = info.class;
                            
                        case 'HDF5'
                            varname_ = ['/' name_];
                            fname=fullfile([varargin{2} '.hd5']);
                            h5create(fname, varname_, size_,'Datatype',class_);
                            obj.diskfile_=hdf5info(fname);
                            h5write(fname, varname_, varargin{3});
                            obj.name_ = varname_;
                            obj.size_ = size(varargin{3});
                            obj.class_ = class_;
                            obj.type_='HDF5';
                            obj.bytes_ = obj.diskfile_.FileSize;

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
                switch S(ii).type_
                    case '()'
                        if ii==1
                            Out='obj.diskfile_.(obj.name_)';
                            
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
                        end
%                         S(ii).subs=cellfun( @(x) num2str(x), S(ii).subs ,'UniformOutput',false);
                        % wow, this is actally working! unexpected
                        % redirecting the indexing operation from the object to
                        % the variable stored in the matfile
                        Out = sprintf('%s(S(ii).subs{:})',Out);
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
            for i=1:nargout
                varargout(i) = {Out};
            end
        end
        
         function obj = subsasgn(obj,S,b)
             tmp = obj.diskfile_.(obj.name_);
             for ii=1:numel(S)
                 switch S(ii).type_
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
            info = whos(obj.diskfile_);
            cl = info.class;
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
            name_O = Out.name_;
            if isa(b,'orgExp.libs.DiskData')
                name_B = b.name_;
                Out.diskfile_.Properties.Writable=true;
                Out.diskfile_.(name_O)(1,(obj.size(2)+1):(obj.size(2)+b.size(2)))...
                    = b.diskfile_.(name_B)(1,:);
            elseif isempty(obj.diskfile_.(obj.name_))
                 Out.diskfile_.(name_O) = b;
            elseif class(obj)==class(b)
                Out.diskfile_.(name_O)(1,(obj.size(2)+1):(obj.size(2)+size(b,2)))...
                    = b;
            else
                error('Cannot concatenate objects of different classes');
            end
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

