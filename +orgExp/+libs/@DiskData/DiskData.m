classdef DiskData
    %DISKDATA 
    
    properties (Access = private)
        diskfile
        name
        size_
        bytes
        class_
    end
    
    methods
        function obj = DiskData(inputArg1)
            %DISKDATA Constructor
            if isa(inputArg1,'matlab.io.MatFile')
                obj.diskfile = inputArg1;
                info = whos(obj.diskfile);
                obj.name = info.name;
                obj.size_ = info.size;
                obj.bytes = info.bytes;
                obj.class_ = info.class;
            else
                error('Datatype not yet supported');
            end
        end
        
        function Out = subsref(obj,S)

            switch S.type 
                case '()'
                    
                    SizeCheck=cellfun( @(x) max(x), S.subs )>obj.size;
                    
                    nArgs=numel(S.subs);
                    if nArgs==1
                        [~,I]=max(obj.size_);                        
                        tmp=S.subs{1};
                        S.subs(1:numel(obj.size_))={1};
                        S.subs{I}=tmp;                        
                    end
                    if nArgs>numel(obj.size)
                        error('Index exceeds matrix dimension.');
                    elseif any(SizeCheck(~any(strcmp(S.subs,':'))))
                        error('Index exceeds matrix dimension.');
                    end
                   
                    
                    % wow, this is actally working! unexpected
                    % redirecting the indexing operation from the object to
                    % the variable stored in the matfile
                    Out = obj.diskfile.(obj.name)(S.subs{:});
                    
                case '{}'
                    warning('curly indexing not supported yet')
                case '.'
                    warning('dot referencing not supported yet')
            end
        end
        
        function Out = minus(obj,b)
            if isa(b,'orgExp.libs.DiskData')
               Out=obj.diskfile.(obj.name)(:,:)-b.diskfile.(b.name)(:,:);
            elseif isnumeric(b)
                Out=obj.diskfile.(obj.name)(:,:)-b;
            end
        end
        
        function dim = size(obj)
            dim=obj.size_;
        end        
        function cl=class(obj)
            cl= obj.class_;
        end        
        function l=length(obj)
           l=max(obj.size_);
        end
        function Out = double(obj)
           Out= double(obj.diskfile.(obj.name)(:,:));
        end
        
        function Out = getPath(obj)
            Out=obj.diskfile.Properties.Source;
        end
    end
end

