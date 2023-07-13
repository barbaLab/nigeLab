classdef namingConfigurator < handle
    properties
       nigelObj
       FileName 
       Fig
       NamingConvention
       DiscardChar
       IncludeChar
       SpecialMeta      (1,1)struct 
       Delimiter
       
       NamePanel
       MetasPanel
       SpecialPanel
       
       DelimiterField
       FileNameEdtFld
       srcFileBtn
       
       MetaEdt          matlab.ui.control.EditField
       MetaChk          matlab.ui.control.CheckBox
       SaveBtn
       Save2AllBtn
    end
    
    methods
        
        function obj = namingConfigurator(nigelObj,fname)
            
            if nargin < 2
                if isprop(nigelObj,'Meta') && isfield(nigelObj.Meta,'OrigName')
                    fname = nigelObj.Meta.OrigName;
                else
                  fname = '';  
                end
            end
            obj.nigelObj = nigelObj;
            type = nigelObj.Type;
            obj.FileName = fname;
            obj.DiscardChar = nigelObj.Pars.(type).DiscardChar;
            obj.IncludeChar = nigelObj.Pars.(type).IncludeChar;
            obj.SpecialMeta.SpecialVars = {};
            
            obj.Fig = uifigure('Position',[300 150 640 480],'CloseRequestFcn',@(src,evt)CloseFig(obj));
            obj.SpecialPanel  = uipanel(obj.Fig,'Scrollable','on','Units','normalized','Position',[ 0 .1 1 .3],'Scrollable','on','UserData',0);
            obj.MetasPanel = uipanel(obj.Fig,'Scrollable','on','Units','normalized','Position',[ 0 .4 1 .3],'Scrollable','on');
            obj.NamePanel= uipanel(obj.Fig,'Scrollable','on','Units','normalized','Position',[ 0 .7 1 .3],'Scrollable','on');
            obj.SaveBtn = uibutton(obj.Fig,'Text','Save','Position',[320 10 100 20],'ButtonPushedFcn',@(src,evt)obj.save);
            obj.Save2AllBtn = uibutton(obj.Fig,'Text','Save to all','Position',[430 10 200 20],'ButtonPushedFcn',@(src,evt)obj.save2all,...
                'Enable',false); 
            if ~isa(obj.nigelObj,'nigeLab.Tank')
                set(obj.Save2AllBtn,'Enable',true);
            end
            % build Name panel
            obj.NamePanel.Units = 'pixels';
            pos = obj.NamePanel.Position;
            obj.NamePanel.Units = 'normalized';
             
            w = 400;
            h = 20;
            uilabel(obj.NamePanel,'Text','File name',...
                'Position',[30 pos(4)-30 w h]);
            obj.FileNameEdtFld = uieditfield(obj.NamePanel,'Tooltip','Enter the character that divides the name metadata',...
                'Position',[30 pos(4)-30-h-2 w h],'ValueChangedFcn',@(src,evt)set(obj,'',src.Value),'Value',obj.FileName);
         
            obj.srcFileBtn = uibutton(obj.NamePanel,'Text','...','Position',[30+w+2 pos(4)-30-h-2 30 h]);
            
            w = 100;
            h = 20;
            uilabel(obj.NamePanel,'Text','Split character(s)',...
                'Position',[pos(3)-30-w pos(4)-30 w h]);
            obj.DelimiterField = uieditfield(obj.NamePanel,'Tooltip','Enter the character that divides the name metadata',...
                'Position',[pos(3)-30-w-2 pos(4)-30-h-2 w h],'ValueChangedFcn',@(src,evt)obj.buildMetaGUI(src));
            
            if isfield(nigelObj.Pars.(type),'VarExprDelimiter')
                src.Value = sprintf('%s ',nigelObj.Pars.(type).VarExprDelimiter{:});
                obj.DelimiterField.Value = src.Value;
                obj.buildMetaGUI(src);
                obj.Delimiter = src.Value;
            end
            
            % SpecialMeta Variables
            uibutton(obj.SpecialPanel,'Text','Add SpecialMeta variable','Position',[30 h-10 200 h],'ButtonPushedFcn',@(~,~)obj.addSpecialMetaVar);
            
            
        end
        
        function addSpecialMetaVar(obj)
            nameComp = strsplit(obj.FileName,arrayfun(@(x) x,obj.Delimiter,'UniformOutput',false));
            obj.SpecialPanel.Units = 'pixels';
            pos = obj.SpecialPanel.Position;
            obj.SpecialPanel.Units = 'normalized';
            h = 20;
            w = 100;
            hoffs = 200;   
            hStep = 25;
            voffs = (obj.SpecialPanel.UserData+1)*(h + hStep)+20;
            obj.SpecialPanel.UserData = obj.SpecialPanel.UserData + 1;
            lbl_ = uilabel(obj.SpecialPanel,'Text','Special Meta Name','Tooltip','Insert here the special meta variable name',...
                'Position',[30 voffs w h]);
            SpecialMetaEdt = uieditfield(obj.SpecialPanel,'Tooltip','Enter the metadata name',...
                'Position',[30 voffs-h-2 w h]);
            
            
            
            
            enabled = [obj.MetaEdt.Enable];
            N = sum(enabled);
            enabled = find(enabled);
            for ii = 1:N
                lbl(ii) = uilabel(obj.SpecialPanel,'Text',obj.NamingConvention{enabled(ii)}(2:end),'Tooltip',nameComp{enabled(ii)},...
                    'Position',[hoffs voffs w h],'Userdata',nameComp{enabled(ii)});
                SpecialMetaChk(ii) = uicheckbox(obj.SpecialPanel,'Tooltip','Tick to join the metadata',...
                    'Position',[hoffs + 5 voffs-h-1 10 10],...
                    'Enable','off' );
                %uilabel(pan,'Text','_','Position',[hoffs + w + 10 voffs 10 h]);
                hoffs = hoffs + w + 10;
            end
            
            hoffs = max(hoffs + w,pos(3)-2*w-55);
            SpecialMetaPrwlbl = uilabel(obj.SpecialPanel,'Text','','Tooltip','Special Meta preview',...
                'Position',[hoffs voffs w h]);
            SpecialMetaPrw = uilabel(obj.SpecialPanel,'Text','','Tooltip','Special Meta preview',...
                'Position',[hoffs voffs-h-2 w h]);
            
            hoffs = hoffs + w+20;
            hObjArray = [SpecialMetaPrw, SpecialMetaPrwlbl, lbl,SpecialMetaChk,SpecialMetaEdt,lbl_];
            uibutton(obj.SpecialPanel,'Text','Delete','Position',[hoffs voffs 50 h],'ButtonPushedFcn',@(src,~)delAllObjs([hObjArray src],obj,h+hStep));

            
            arrayfun(@(idx) set(SpecialMetaChk(idx),'ValueChangedFcn',@(evt,src)SpecialMetaChecked(evt,lbl(idx),obj,SpecialMetaPrw)),1:N  )
            SpecialMetaEdt.ValueChangedFcn = @(src,evt)SpecialMetaNamed(src,obj,SpecialMetaChk, SpecialMetaPrwlbl);
            
            function SpecialMetaChecked(evt,lbl,obj,SpecialMetaPrw)                
                if evt.Value
                    obj.SpecialMeta.(evt.UserData).vars{end+1} = lbl.Text;
                    SpecialMetaPrw.Text = [SpecialMetaPrw.Text obj.SpecialMeta.(evt.UserData).cat lbl.UserData];
                else
                    idx =  strcmp(obj.SpecialMeta.(evt.UserData).vars,lbl.Text);
                    obj.SpecialMeta.(evt.UserData).vars(idx) = [];
                    
                    str = strsplit(SpecialMetaPrw.Text,obj.SpecialMeta.(evt.UserData).cat);
                    SpecialMetaPrw.Text = strjoin(str(~idx),obj.SpecialMeta.(evt.UserData).cat);
                end
            end
            
            function SpecialMetaNamed(this,obj,SpecialMetaChk,PrwLbl)
                field = strrep(this.Value,' ','');
                this.Value = field;
                OldField = SpecialMetaChk(1).UserData;
                if isempty(field)
                    this.Value = OldField;
                    return;
                end
                if ~isempty(OldField)
                    obj.SpecialMeta.SpecialVars(strcmp(obj.SpecialMeta.SpecialVars,OldField)) = {field};
                    obj.SpecialMeta.(deblank(field)).vars = obj.SpecialMeta.(OldField).vars;
                    obj.SpecialMeta = rmfield(obj.SpecialMeta,OldField);
                else
                    obj.SpecialMeta.SpecialVars{end+1} = deblank(field);
                    obj.SpecialMeta.(deblank(field)).vars = [];
                    obj.SpecialMeta.(deblank(field)).cat = '-';
                end
                PrwLbl.Text = field;
                [SpecialMetaChk.Enable] = deal('on');
                [SpecialMetaChk.UserData] = deal(deblank(field));
            end
            
            function delAllObjs(hobjarray,obj,hoffs)
                field = hobjarray(end-2).Value;
                if ~isempty(field)
                    obj.SpecialMeta.SpecialVars(strcmp(obj.SpecialMeta.SpecialVars,field)) = [];
                    obj.SpecialMeta = rmfield(obj.SpecialMeta,field);
                end
                
                
                 
                for o = obj.SpecialPanel.Children'
                    if o.Position(2) > hobjarray(1).Position(2)
                        o.Position(2) = o.Position(2) - hoffs;
                    end
                end
                obj.SpecialPanel.UserData = obj.SpecialPanel.UserData -1;
                delete(hobjarray);
            end
        end
        
        function buildMetaGUI(obj,src)
            name = obj.FileName;
            fig = obj.Fig;
            pan = obj.MetasPanel;
            pan.Units = 'pixels';
            for o = pan.Children
                delete(o);
            end
            
            obj.MetaEdt = repmat(obj.MetaEdt,0,0);
            obj.MetaChk = repmat(obj.MetaChk,0,0);
            nameComp = strsplit(name,arrayfun(@(x) x,src.Value,'UniformOutput',false));
            obj.Delimiter = src.Value;
            obj.NamingConvention = repmat({obj.DiscardChar},1,numel(nameComp));
            pos = pan.Position;
            pan.Units = 'normalized';
            voffs =  pos(4)-30;
            hoffs = 50;
            w = 100;
            h = 20;
            for ff = 1: numel( nameComp)
                lbl(ff) = uilabel(pan,'Text',nameComp{ff},'Tooltip',nameComp{ff},...
                    'Position',[hoffs voffs w h]);
                obj.MetaEdt(ff) = uieditfield(pan,'Tooltip','Enter the metadata name',...
                    'Position',[hoffs voffs-h-2 w h],'ValueChangedFcn',@(evt,src)obj.setMetaName(ff,src));
                obj.MetaChk(ff) = uicheckbox(pan,'Tooltip','Tick to store the metadata',...
                    'Position',[hoffs + w/2-5 voffs-h*2-1 10 10],'ValueChangedFcn',@(evt,src)obj.checkCallback(evt,src,lbl(ff),obj.MetaEdt(ff)));
                %uilabel(pan,'Text','_','Position',[hoffs + w + 10 voffs 10 h]);
                hoffs = hoffs + w + 10;
                evt.Value = 0;
                obj.checkCallback(evt,[],lbl(ff),obj.MetaEdt(ff))
            end
            % make navigation through tab possible
            idx = ismember(pan.Children,obj.MetaEdt);
            pan.Children = pan.Children([find(idx);find(~idx)]);
        end
        
        function setMetaName(obj,idx,src)
            obj.NamingConvention{idx} = [obj.IncludeChar src.Value];
        end
        
        function checkCallback(obj,evt,src,lbl,edt)
            r = [    0.8784    0.3216    0.3216];
            if evt.Value
                edt.BackgroundColor = [0.4157 0.7686 0.3922];
                lbl.FontColor = [0.4157 0.7686 0.3922];
                edt.Enable = true;
            else
                edt.BackgroundColor = r;
                lbl.FontColor = r;
                edt.Enable = false;
                idx = ismember(obj.MetaEdt,edt);
                obj.NamingConvention(idx) = {obj.DiscardChar};
            end
            
        end
        
        function pars = save(obj,closeFig)
            if nargin < 2
                closeFig = false;
            end
            type = obj.nigelObj.Type;
            pars = struct();
            pars.NamingConvention = obj.NamingConvention;
            pars.SpecialMeta = obj.SpecialMeta;
            pars.Delimiter = unique(obj.Delimiter);
            pars.Delimiter = cellstr(pars.Delimiter(:));
            pars.IncludeChar = obj.IncludeChar;
            pars.DiscardChar = obj.DiscardChar;
            switch type
                case 'Tank'
                    isTankIdPresent = any(strcmp([obj.IncludeChar 'TankID'],obj.NamingConvention)) || ...
                        any(strcmp('TankID',fieldnames(obj.SpecialMeta)));
                    if  isTankIdPresent 
                        ok = true;
                    else
                        error('Please provide an unique Tank identifier called TankID');
                    end
                case 'Animal'
                    isAnIdPresent = any(strcmp([obj.IncludeChar 'AnimalID'],obj.NamingConvention)) || ...
                        any(strcmp('AnimalID',fieldnames(obj.SpecialMeta)));
                    if isAnIdPresent
                        ok = true;
                    else
                        error('Please provide an unique Animal identifier called AnimalID');
                    end
                case 'Block'
                    isRecIdPresent = any(strcmp([obj.IncludeChar 'BlockID'],obj.NamingConvention)) || ...
                        any(strcmp('BlockID',fieldnames(obj.SpecialMeta)));
                    isAnIdPresent = any(strcmp([obj.IncludeChar 'AnimalID'],obj.NamingConvention)) || ...
                        any(strcmp('AnimalID',fieldnames(obj.SpecialMeta)));
                    if  isRecIdPresent && isAnIdPresent
                       ok = true;
                    elseif ~isRecIdPresent
                        error('Please provide an unique Block identifier called BlockID');
                    else
                        error('Please provide an unique Animal identifier called AnimalID');
                    end
            end
            
            ff = fieldnames(pars);
            for f = ff'
                obj.nigelObj.Pars.(type).(f{:}) = pars.(f{:});
            end
            if closeFig
                CloseFig(obj);
            end
        end
        
        function save2all(obj)
            pars = obj.save(false);
            type = obj.nigelObj.Type;
            parent =  obj.nigelObj.Parent;
            grandparent = [parent.Parent];
            for oo = parent
                ff = fieldnames(pars);
                for f = ff'
                    oo.Pars.(type).(f{:}) = pars.(f{:});
                    for ooP = grandparent
                        ooP.Pars.(type).(f{:}) = pars.(f{:});
                    end
                end
            end
            CloseFig(obj);
        end
        
        function CloseFig(obj)
            delete(obj.Fig);
            obj.nigelObj = [];
            delete(obj);
        end
    end
end