function flag = doTrialVidExtraction(blockObj)
%DOTRIALVIDEXTRACTION  Extract Trial Videos 
%
%  flag = doTrialVidExtraction(blockObj);

if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      flag = flag && doTrialVidExtraction(blockObj(i));
   end
   return;
end

if isempty(blockObj)
   flag = true;
   return;
elseif ~isvalid(blockObj)
   flag = true;
   return;
end

if ~checkActionIsValid(blockObj)
   flag = true;
   return;
end

end