function varargout = Tank(varargin)
%TANK  Template for initializing parameters for nigeLab.Tank class
%
%   pars = nigeLab.defaults.Tank;

pars = struct;
pars.BlockNameVars = {'Animal_ID'; ...
                         'Year'; ...
                         'Month'; ...
                         'Day'; ...
                         'Block_ID'};
pars.SaveLocDefault = 'C:\Users\Fede\Documents\Eperiments\Alberto\Extracted_Data_To_Move';
pars.DefaultRecLoc = 'C:\Users\Fede\Documents\Eperiments\Alberto\RAW';
pars.RecType = 'Intan';
pars.FolderIdentifier = '.nigelTank';

%% Name parsing: see '~/+defaults/Block.m' for detailed documentation
% This works the same way, but applies to Tank name
pars.DynamicVarExp={'$TankID'};
pars.NamingConvention={'TankID'};

pars.SpecialMeta = struct;
pars.SpecialMeta.SpecialVars = {};

% % Example "SpecialMeta" (no current Tank SpecialMeta convention)
% pars.SpecialMeta.ExampleVar.cat = '-'; % Concatenater (if used) for names
% pars.SpecialMeta.ExampleVar.vars = {'TankID','SomethingElse'}; 
% % Note: this example would require that 'SomethingElse' is parsed 
% %       (and Included) in DynamicVarExp

pars.Delimiter   = '_'; % delimiter for variables in TANK name
pars.Concatenater = '_'; % concatenater for variables INCLUDED in TANK name
pars.VarExprDelimiter = {'-','_'}; % Delimiter for parsing "special" vars
pars.IncludeChar='$'; % Delimiter for INCLUDING vars in name
pars.DiscardChar='~'; % Delimiter for excluding vars entirely (don't keep in meta either)

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

