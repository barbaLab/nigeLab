function str =  ToString(in1)
%TOSTRING Universal to string convertor

if iscell(in1)
    if isscalar(in1)
        str = {nigeLab.utils.ToString(in1{1})};
    elseif isempty(in1)
        str = '';
    else
        str = [{nigeLab.utils.ToString(in1{1})},...
            nigeLab.utils.ToString(in1(2:end))];
    end
    return;
end

if isnumeric(in1) ||  islogical(in1)
    str = num2str(in1);

elseif isa(in1,'function_handle')
    str = func2str(in1);
    
elseif ischar(in1)
    str = in1;
    
end
    
end

