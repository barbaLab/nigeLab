function [flag] = checkStructUniformity(struct1,struct2,CheckClass)
%CHECK Summary of this function goes here
%   Detailed explanation goes here

if nargin<3
    CheckClass = true;
end

fields1 = fieldnames(struct1);
fields2 = fieldnames(struct2);

n1 = numel(struct1);
n2 = numel(struct2);

flag = true;

fieldsDiff = setdiff(fields1,fields2);
if not(isempty(fieldsDiff))
    flag = false;
    return;
elseif not(n1 == n2) 
    flag = false;
    return;
else
    for ii = 1:n1
        if CheckClass
            cls1 = structfun(@class,struct1(ii),'UniformOutput',false);
            cls2 = structfun(@class,struct2(ii),'UniformOutput',false);
            flag = flag && ...
                nigeLab.utils.checkStructUniformity(cls1,cls2,false);
        end
        if not(flag)
            return;
        end
        for ff = 1:numel(fields1)     % same as fields2
            % same as n2
            flag = flag &...
                isequal(struct1(ii).(fields1{ff}), struct2(ii).(fields2{ff}));
            if not(flag)
                return;
            end
        end
    end
end


end

