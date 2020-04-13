function varargout = Probe(varargin)
%PROBE   Template for initializing parameters for probe data
%
%   pars = nigeLab.defaults.Probe;

pars = struct;
[pars.Folder,~,~] = fileparts(mfilename('fullpath'));
pars.File = 'Probes.xlsx';
pars.Str = '%s.xlsx';
pars.Delimiter = '_';
pars.ElectrodesFolder = 'K:\Rat\Electrodes';
pars.ProbeIndexParseFcn = @(str)(str2double(str(2))-1);

%% Parse output
if nargin < 1
   varargout = {pars};
else
   varargout = cell(1,nargin);
   f = fieldnames(pars);
   for i = 1:nargin
      idx = ismember(lower(f),lower(varargin{i}));
      if sum(idx) == 1
         varargout{i} = pars.(f{idx});
      end
   end
end

end