function flag = doEventDetection(blockObj,force)
% DOEVENTDETECTION  "Detects" putative Trial events
%
%  flag = doEventDetection(blockObj,EventName,StreamName); 
%       Performs Event detection from streams.
%       Timestamps are extracted from StreamName and saved in the Events
%       struct using the tag provided in EventName.
flag = true;

if nargin < 2
   force = false;
end

% handle block array
if numel(blockObj) > 1
   for i = 1:numel(blockObj)
      flag = flag && doEventDetection(blockObj(i),...
         force);
   end
   return;
end

%% Preliminary checks and controls
checkActionIsValid(blockObj);                                               % check if event detection can be performed 
ePars = blockObj.Pars.Event;                                                % retrieve the parameters
if ~force
    str = 'This will replace any events called ';                           % ask user consent to eventually replace events 
    for ff = ePars.EvtNames(:)'
        str = [str ff{1} ' or '];
    end
    str = [str(1:end-4) '.' newline 'Do you want to continue?'];
    selection = questdlg(sprintf(str),...
        'Do event detection?',...
        'Detect events','Cancel','Cancel');
    
    if strcmp(selection,'Detect events')
        ... Nothing to do here
    elseif strcmp(selection,'Cancel') || isempty(selection)
    fprintf(1,'Operation aborted.\n');
    return;
    end
end                                                                         % If the operation is 'forced', the consent is skipped

%% Retrieve the events from the streams
for ff = ePars.EvtNames(:)'                                                 % Loop on events type
    try
    thisStream = blockObj.getStream(ePars.(ff{:}).Source);                  % retrieve the stream
      ts = num2cell(nigeLab.utils.binaryStream2ts(...                       % use util function to get Ts from the binary stream
          thisStream.data,thisStream.fs,...
            ePars.(ff{:}).Threshold,...
            ePars.(ff{:}).DetectionType,...
            ePars.(ff{:}).Debounce));

        thisEvt(length(ts)) = struct();                                     % Allocate a structarray same length as Ts
        [thisEvt.Ts] = deal(ts{:});                                         % and populate it
        [thisEvt.Tag] = deal(ePars.(ff{:}).Tag);
        [thisEvt.Name] = deal(ff{:});
        [thisEvt.Duration] = deal(1);
        [thisEvt.Data] = deal([]);
        [thisEvt.Trial] = deal(nan);
        if isfield(blockObj.Events,'Name')
            blockObj.Events(strcmp([blockObj.Events.Name],ff{:})) = [];     % remove duplicates
        end


        


      blockObj.Events = [blockObj.Events thisEvt];                          % Add all events of this type to block
      clear('thisEvt');                                                     % cleanup thisEvt to avoid conflicts
      flag = flag & true;                                                   % update flag to signal all is good
    catch er
                                                                            % if something goes wrong, report to user without stopping  execution
        disp( getReport( er, 'extended', 'hyperlinks', 'on' ) );
        flag = flag & false;
    end
end    
blockObj.save;

end