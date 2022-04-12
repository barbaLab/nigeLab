function VideoScoringHotkeyHelpFcn()
% VIDEOSCORINGHOTKEYHELPFCN  programmatically generates documentation for
% VideoScoringHotkey.
%
%  Issued whenever h is pressed in VideoScorer.
% Reads the hotkey files and matches the hotkey with the interface function
% it is linked with


% read Hotkey File
f = fileread(fullfile(nigeLab.utils.getNigelPath,'+nigeLab','+workflow','VideoScoringHotkey.m'));
% segment file on 'case'
idx = [strfind(f,'case') strfind(f,'%% DO NOT CHANGE')-7];
ccIdx = arrayfun(@(i)(idx(i)+5):(idx(i+1)-1),1:numel(idx)-1,'UniformOutput',false);
f_case = cellfun(@(idx) f(idx),ccIdx,'UniformOutput',false);
% remove all comments
f_case = cellfun(@(str) regexprep(str,['%.*?' newline],''),f_case,'UniformOutput',false);
for ss = 1:numel(f_case)
    str = f_case{ss};
    keys = regexp(str,'{.*}','match','once');
    if isempty(keys)
        keys = regexp(str,"('\w*')?",'match','once');
    else
        keys([1 end]) = '';
    end
% 

    str = strrep(str,keys,'');
    actions = regexp(str,"(add\(obj,'\w*','\w*'(,.*)?\);){1}|playpause|(previous|next)(Frame|Trial)",'match');

    ThisKeyActions = '';
    for aa=1:numel(actions)
        if regexp(actions{aa},"add\(obj,'ev(t|ents?)'",'once')
            evtsAdded = regexp(actions{aa},"add\(obj,'ev(t|ents?)','(?=\w*')|'\);",'split');
            evtsAdded([1 end])=[];
            ThisKeyActions = [ThisKeyActions newline sprintf('Adds an event to current timestamp with Name %s;',evtsAdded{1})];
        elseif regexp(actions{aa},"add\(obj,'l(bl|abels?)'",'once')
            lblsAdded = regexp(actions{aa},"add\(obj,'l(bl|abels?)','(?=\w*')|',(?=.*\))|\);",'split');
            lblsAdded([1 end])=[];
            ThisKeyActions = [ThisKeyActions newline sprintf('Adds a label to current trial with Name %s and Value %s;',lblsAdded{1},lblsAdded{2})];
        elseif regexp(actions{aa},"playpause",'once')
            ThisKeyActions = [ThisKeyActions newline 'Toggles play/pause in the primary view;'];
        elseif regexp(actions{aa},"previousFrame",'once')
            ThisKeyActions = [ThisKeyActions newline 'Backs up one frame in all active views;'];
        elseif regexp(actions{aa},"previousTrial",'once')
            ThisKeyActions = [ThisKeyActions newline 'Jumps to the previous trial in all active views;'];
        elseif regexp(actions{aa},"nextFrame",'once')
            ThisKeyActions = [ThisKeyActions newline 'Advances one frame in all active views;'];
        elseif regexp(actions{aa},"nextTrial",'once')
            ThisKeyActions = [ThisKeyActions newline 'Jumps to the next trial in all active views;'];
        else
        end
    end
if isempty(ThisKeyActions)
    if contains(str,'VideoScoringHotkeyHelpFcn')
        ThisKeyActions = [ThisKeyActions newline 'Prints this help;'];
    elseif isempty(str)
        continue;
    end
end

    fprintf('Pressing key %s\t%s\n\n',keys,ThisKeyActions);
end



end