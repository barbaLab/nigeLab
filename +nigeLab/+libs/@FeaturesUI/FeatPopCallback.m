function FeatPopCallback(obj,this,~)
%% FEATPOPCALLBACK  Callback function from FEATURES popup box
%
%  set(gco,'Callback',@obj.FeatPopCallback);
%
%

switch this.Tag
    case 'Dim1'
        other = obj.FeatY;
        % get dropdown values
        usrDat = this.UserData;
        selectVal = this.Value;
        
        % get dropdown values from other dropdown for backup
        usrDatOther = other.UserData;
        selectValOther = other.Value;
        OldValOther = usrDatOther(selectValOther);
        
        obj.featInd(1) = usrDat(selectVal);
        ind = obj.Parent.UI.feat.combo(:,1) == usrDat(selectVal);
        vals=unique(obj.Parent.UI.feat.combo(ind,2));
        str = obj.Parent.UI.feat.name(vals);

        set(other,'UserData',vals)
        set(other,'String',str)
        tmp=find(vals==OldValOther);
        if isempty(tmp),tmp=1;end
        set(other,'Value',tmp)
        obj.featInd(2) = vals(tmp);
    case 'Dim2'
        other = obj.FeatX;
        % get dropdown values
        usrDat = this.UserData;
        selectVal = this.Value;
        
        % get dropdown values from other dropdown for backup
        usrDatOther = other.UserData;
        selectValOther = other.Value;
        OldValOther = usrDatOther(selectValOther);
        
        obj.featInd(2) = usrDat(selectVal);
%         ind = obj.Parent.UI.feat.combo(:,2) == usrDat(selectVal);
%         vals=unique(obj.Parent.UI.feat.combo(ind,1));
%         str = obj.Parent.UI.feat.name(vals);
% 
%         set(other,'UserData',vals)
%         set(other,'String',str)
%         tmp=find(vals==OldValOther);
%         if isempty(tmp),tmp=1;end
%         set(other,'Value',tmp)

end

obj.projVecs = zeros(size(obj.projVecs));
obj.projVecs(1,obj.featInd(1)) = 1;
obj.projVecs(2,obj.featInd(2)) = 1;
obj.PlotFeatures();
obj.ResetFeatureAxes();
end