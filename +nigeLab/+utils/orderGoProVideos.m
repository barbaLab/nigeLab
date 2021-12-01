
function index = orderGoProVideos(nameList)
regexp1 = 'G[HXS]\d{2}\d{4}(.*)?';
regexp2 = 'G[OP](PR|\d{2})\d{4}(.*)?';

index = [];
if ~any(cellfun(@isempty,regexp(nameList,regexp1)))
    nameList = cellfun(@(x,y)x(y:end),nameList,regexp(nameList,regexp1),'UniformOutput',false);

    % Hero 6 to 9
    Chapters = cellfun(@(x) x(5:8),nameList,'UniformOutput',false);
    uChap = unique(Chapters)';
    for Ch = uChap
        thisChapsIdx = find(contains(nameList,Ch));
        thisChaps = nameList(thisChapsIdx);
        ChapNum = cellfun(@(x) x(3:4),thisChaps,'UniformOutput',false);
        [~,i] = sort(ChapNum);
        index = [index thisChapsIdx(i)'];
        
    end
    
elseif ~any(cellfun(@isempty,regexp(nameList,regexp2)))
        nameList = cellfun(@(x,y)x(y:end),nameList,regexp(nameList,regexp2),'UniformOutput',false);
    
    % Hero 2 to 5
    Chapters = cellfun(@(x) x(5:8),nameList,'UniformOutput',false);
    uChap = unique(Chapters);
    for Ch = uChap
        thisChapsIdx = find(contains(nameList,Ch));
        thisChaps = nameList(thisChapsIdx);
        ChapNum = cellfun(@(x) x(3:4),thisChaps,'UniformOutput',false);
        [~,i] = sort(ChapNum);
        i = circshift(i,1);
        index = [index thisChapsIdx(i)'];
    end
else
    index = 1:numel(nameList);
    warning('No match found! Files can be unordered.');
end
index = index(:);
end