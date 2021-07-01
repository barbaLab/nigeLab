function flag = doEventDetection(blockObj,EventName,StreamName)
% DOEVENTDETECTION  "Detects" putative Trial events
%
%  flag = doEventDetection(blockObj,EventName,StreamName); 
%       Performs Event detection from streams.
%       Timestamps are extracted from StreamName and saved in the Events
%       struct using the tag provided in EventName.

if nargin < 3
   forceHeaderExtraction = [];
end

if nargin < 2
   vidOffset = [];
end

if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      flag = flag && doEventDetection(blockObj(i),...
         behaviorData,vidOffset,forceHeaderExtraction);
   end
   return;
else
   flag = false;
end

% Check that this can be done and make shortcut to video and event params
checkActionIsValid(blockObj);
ePars = blockObj.Pars.Event;

%
% Always extract 'Trial' first
for ff = ePars.EvtNames(:)'
    try
    thisStream = blockObj.getStream(ePars.(ff{:}).Source);
      ts = num2cell(nigeLab.utils.binaryStream2ts(thisStream.data,thisStream.fs,...
            ePars.(ff{:}).Threshold,ePars.(ff{:}).DetectionType,ePars.(ff{:}).Debounce));
        thisEvt(length(ts)) = struct();
        [thisEvt.Ts] = deal(ts{:});
        [thisEvt.Tag] = deal(ePars.(ff{:}).Tag);
        [thisEvt.Name] = deal(ff{:});
        [thisEvt.Duration] = deal(1);
        [thisEvt.Data] = deal([]);
        [thisEvt.Trial] = deal(nan);
      blockObj.Events = [blockObj.Events thisEvt];
      clear('thisEvt');
    catch er
        disp( getReport( me, 'extended', 'hyperlinks', 'on' ) )
    end
end    
blockObj.save;
flag = true;
end