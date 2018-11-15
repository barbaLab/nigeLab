classdef DiskData
    %DISKDATA
    
    properties (Access = private)
        diskfile
        type
        name
        size_
        bytes
        class_
    end
    
    methods
        function obj = DiskData(varargin)
            %DISKDATA Constructor
            switch nargin
                case 1
                    if isa(varargin{1},'matlab.io.MatFile')
                        obj.diskfile = varargin{1};
                        info = whos(obj.diskfile);
                        obj.type='MatFile';
                        obj.name = info.name;
                    else
                        error('Data format not yet supported');
                    end
                case 2
                    switch varargin{1}
                        case 'MatFile'
                            obj.diskfile = matfile(varargin{2},...
                                'Writable',true);
                            if ~exist(varargin{2},'file')
                                obj.diskfile.data = [];
                            end
                            info = whos(obj.diskfile);
                            obj.type='MatFile';
                            obj.name = info.name;
                            obj.size_ = info.size;
                            obj.bytes = info.bytes;
                            obj.class_ = info.class;
                            
                        case 'HDF5'
                        otherwise
                            error('Unknown data format');
                    end
                    
                otherwise
                    error('Wrong number of input parameter');
            end
        end
        
        
        function Out = subsref(obj,S)
            Out=obj.diskfile.(obj.name);
            for ii=1:numel(S)
                switch S(ii).type
                    case '()'  
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
                        
                        
                        % wow, this is actally working! unexpected
                        % redirecting the indexing operation from the object to
                        % the variable stored in the matfile
                        Out = Out(S(ii).subs{:});
                    case '{}'
                        warning('curly indexing not supported yet')
                    case '.'
                        s=methods(obj);
                        if any(strcmp(s,S(ii).subs))
                            Out = obj.(S(ii).subs);
                        else
                            Out = Out.(S(ii).subs);
                        end
                end
            end
        end
        
         function obj = subsasgn(obj,S,b)
             %             obj.diskfile.Properties.Writable=true;
             tmp = obj.diskfile.(obj.name);
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
             obj.diskfile.(obj.name) = tmp;
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
                Out=obj.diskfile.(obj.name)(:,:)-b.diskfile.(b.name)(:,:);
            elseif isnumeric(b)
                Out=obj.diskfile.(obj.name)(:,:)-b;
            end
        end
        
        function dim = size(obj,n)
            info = whos(obj.diskfile);
            if nargin<2
                n=1:length(info.size);
            end
            dim=info.size(n);
        end
        
        function cl=class(obj)
            info = whos(obj.diskfile);
            cl = info.class;
        end
        
        function l=length(obj)
            info = whos(obj.diskfile);
            l=max(info.size);
        end
        
        function Out = double(obj)
            Out= double(obj.diskfile.(obj.name)(:,:));
        end
        
        function Out = getPath(obj)
            Out=obj.diskfile.Properties.Source;
        end
        
        function Out = append(obj,b)
            Out = obj;
            nameO = Out.name;
            if isa(b,'orgExp.libs.DiskData')
                nameB = b.name;
                Out.diskfile.Properties.Writable=true;
                Out.diskfile.(nameO)(1,(obj.size(2)+1):(obj.size(2)+b.size(2)))...
                    = b.diskfile.(nameB)(1,:);
            elseif isempty(obj.diskfile.(obj.name))
                 Out.diskfile.(nameO) = b;
            elseif class(obj)==class(b)
                Out.diskfile.(nameO)(1,(obj.size(2)+1):(obj.size(2)+size(b,2)))...
                    = b;
            else
                error('Cannot concatenate objects of different classes');
            end
        end
        
        function disp(obj)
            disp(obj.diskfile.(obj.name));
        end
        
        function n=numel(obj)
            n=numel(obj.diskfile.(obj.name));
        end
        
        function x=abs(obj)
            x = abs(obj.diskfile.(obj.name));
        end
        
        function b = isempty(obj)
            b = isempty(obj.diskfile.(obj.name));
        end
        
    end
end
