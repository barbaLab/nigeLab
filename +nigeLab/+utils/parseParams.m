function p = parseParams(cfg_key,arg_pairs,varargin)
%% PARSEPARAMS    p = utils.parseParams(cfg_key,arg_pairs);
%
%  cfg_key : Leading char array for desired config prop 
%              (e.g. 'ShadedError_' or 'SignificanceLine_')
%
%  arg_pairs : 'Name', value, input argument pairs (varargin from main
%                 function).
%
%  p : Struct of appropriate output parameters

%% 
if isstruct(cfg_key)
	p = cfg_key;
	cfg_key = arg_pairs;
	arg_pairs = varargin{1};
else % DEFAULT PACKAGE PARAMS IS "GFX"
	p = gfx.cfg;
end

nKey = numel(cfg_key);
if isempty(arg_pairs)
   return;
end

for i = 1:2:numel(arg_pairs)
   if ~ischar(arg_pairs{i})
      warning('Bad varargin ''name'', value syntax. Check inputs.');
      continue;
   end
   
   if numel(arg_pairs{i}) >= nKey
      if ~strcmpi(arg_pairs{i}(1:nKey),cfg_key)
         arg_pairs{i} = [cfg_key arg_pairs{i}];
      end
   else
      arg_pairs{i} = [cfg_key arg_pairs{i}];
   end
   
   p = utils.setParamField(p,arg_pairs{i},arg_pairs{i+1});
end

end