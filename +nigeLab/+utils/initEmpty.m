function varargout = initEmpty()
%% INITEMPTY   [var1,var2,...] = utils.initEmpty; % Initialize empty array
%
%  varargout = INITEMPTY;
%
%  Initialize an empty array for each requested output argument.

%%

varargout = cell(nargout,1);
for iV = 1:numel(varargout)
   varargout{iV} = [];
end

end