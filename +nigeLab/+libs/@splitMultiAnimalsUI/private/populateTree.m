function populateTree(Tree)
for kk= 1:size(Tree,1)
    for tt=1:size(Tree,2)
        bl = Tree(kk,tt).UserData;
        if ~isempty(Tree(kk,tt).Root.Children),delete(Tree(kk,tt).Root.Children);end
        %% channels
        Channels_T = uiw.widget.TreeNode('Name','Channels',...
            'Parent',Tree(kk,tt).Root,'UserData',0);
        if numel(bl.Channels)>0
            ProbesNames = unique({bl.Channels.port_name});
            AllProbesNumbers = [bl.Channels.port_number];
            ProbesNumbers = unique(AllProbesNumbers);
            Chans = {bl.Channels.custom_channel_name};
            for ii = 1:numel(ProbesNumbers)
                indx = find(AllProbesNumbers == ProbesNumbers(ii));
                Probe_T =  uiw.widget.TreeNode('Name',ProbesNames{ii},...
                    'Parent',Channels_T);
                for jj= indx
                    chan = uiw.widget.TreeNode('Name',Chans{jj},...
                        'Parent',Probe_T,'UserData',[tt,jj]);
                end
            end
        end
        Channels_T.expand();
        %% events
        Evts_T = uiw.widget.TreeNode('Name','Events',...
            'Parent',Tree(kk,tt).Root,'UserData',0);
        EvtTypes = fieldnames(bl.Events);
        for ii =1:numel(EvtTypes)
            EvtType_T =  uiw.widget.TreeNode('Name',EvtTypes{ii},...
                'Parent',Evts_T);
            for jj=1:numel(bl.Events.(EvtTypes{ii}))
                evt = uiw.widget.TreeNode('Name',bl.Events.(EvtTypes{ii})(jj).name,...
                    'Parent',EvtType_T,'UserData',[tt,ii]);
            end
            
        end
        Evts_T.expand();
        %% Streams
        Strms_T = uiw.widget.TreeNode('Name','Streams',...
            'Parent',Tree(kk,tt).Root,'UserData',0);
        streamsType = fieldnames(bl.Streams);
        if numel(streamsType)>0
            for hh=1:numel(streamsType)
                
                StrmGrnPrnt_T =  uiw.widget.TreeNode('Name',streamsType{hh},...
                    'Parent',Strms_T);
                allSignalType = {bl.Streams.(streamsType{hh}).port_name};
                if isempty(allSignalType),continue;end
                signalType = unique(allSignalType);
                Streams = {bl.Streams.(streamsType{hh}).custom_channel_name};
                for ii =1:numel(signalType)
                    indx = find(strcmp(allSignalType,signalType{ii}));
                    StrmPrnt_T =  uiw.widget.TreeNode('Name',signalType{ii},...
                        'Parent',StrmGrnPrnt_T);
                    for jj = indx
                        chan = uiw.widget.TreeNode('Name',Streams{jj},...
                            'Parent',StrmPrnt_T,'UserData',[tt,jj]);
                        
                    end %jj
                end %ii
            end %hh
        end %fi
        Strms_T.expand();
        
        
        
    end % tt
end % kk
end
