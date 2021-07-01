
function index = orderGoProVideos(nameList)
regexp1 = 'G[HXS]\d{2}\d{4}(.*)?';
regexp2 = 'G[OP](PR|\d{2})\d{4}(.*)?';

index = [];
if ~any(cellfun(@isempty,regexp(nameList,regexp1)))
    % Hero 6 to 9
    Chapters = cellfun(@(x) x(5:8),nameList,'UniformOutput',false);
    uChap = unique(Chapters);
    for Ch = uChap
        thisChaps = nameList(contains(nameList,Ch));
        ChapNum = cellfun(@(x) x(3:4),thisChaps,'UniformOutput',false);
        [~,i] = sort(ChapNum);
        index = [index i];
        
    end
    
elseif ~any(cellfun(@isempty,regexp(nameList,regexp2)))
    % Hero 2 to 5
    Chapters = cellfun(@(x) x(5:8),nameList,'UniformOutput',false);
    uChap = unique(Chapters);
    for Ch = uChap
        thisChaps = nameList(contains(nameList,Ch));
        ChapNum = cellfun(@(x) x(3:4),thisChaps,'UniformOutput',false);
        [~,i] = sort(ChapNum);
        i = circshift(i,1);
        index = [index i];
    end
else
    index = 1:numel(nameList);
    warning('No match found! Files can be unordered.');
end
index = index(:);
end