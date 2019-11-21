
function [tt,F_]=uxTableFormat(F,tt,level)
switch level
    case {'Block','Animal'}
        format = 'yyyy-MM-dd';
    case 'Tank'
        format = 'MMM';
end
F_=cell(size(F,2),2);
F_(:,1)=F;
for ii=1:size(F_,1)
    switch F_{ii,1}
        case 'datetime'
            F_{ii,1} = 'date';
            F_{ii,2} = format;
        case 'cell'
            for jj=1:size(tt,1)
                tt{jj,ii} = [tt{jj,ii}{:}];
            end
            F_{ii,1} = class(tt{1,ii});
        case {'int*','double','single'}
            F_{ii,1} = 'numeric';
            
    end
end
end