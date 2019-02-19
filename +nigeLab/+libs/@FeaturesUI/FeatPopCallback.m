function FeatPopCallback(obj,this,~)
%% CRC_FEATPOPCALLBACK  Callback function from FEATURES popup box
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

obj.PlotFeatures();
obj.ResetFeatureAxes();
end