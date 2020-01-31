function varargout = initEventData(nEvent,nSnippet,type)
%INITEVENTDATA   [var1,var2,...] = utils.initEventData(nEvent,nSnippet);
%
%  [var1,...,varK] = nigeLab.utils.initEventData(nEvent,nSnippet);
%  [var1,...,varK] = nigeLab.utils.initEventData(nEvent,nSnippet,type);
%
%  For each requested output argument, request an array of zeros of
%     dimensions [nEvent x max((nSnippet + 4),5)]

% Parse input
if nargin < 3
   type = 0;
end

varargout = cell(nargout,1);
for iV = 1:nargout
   varargout{iV} = nan(nEvent,max(nSnippet+4,5));
   varargout{iV}(:,1) = type;
   if type == 1
      varargout{iV}(:,2) = (1:nEvent).';
      varargout{iV}(:,3) = ones(nEvent,1);
   end
end


end