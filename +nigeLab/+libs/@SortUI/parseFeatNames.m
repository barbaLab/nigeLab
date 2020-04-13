function featName = parseFeatNames(obj)
%PARSEFEATNAMES  Return feature names (if they have not been generated)
%
%  featName = sortObj.parseFeatNames();
%
% Gets feature names from parameters struct or generate them if they
% do not already exist (from an old version of SD code; this method is for
% backwards-compatibility primarily)

pars = obj.Parent.Blocks(1).Pars.SD;
n = size(obj.Parent.spk.feat{1},2);
featName = cell(1,n);

if isfield(pars,'FEAT_NAMES') && numel( pars.FEAT_NAMES)==n
   featName = pars.FEAT_NAMES;
elseif isfield(pars,'FEAT_NAMES')
   for ii = numel(pars.FEAT_NAMES):n
      featName{ii} = sprintf('feat-%02g',ii);
   end
else
   for i = 1:n
      featName{i} = sprintf('feat-%02g',i);
   end
end
end