function varargout = Animal(varargin)
% ANIMAL  Template for initializing parameters for nigeLab.Animal class
%
%   pars = nigeLab.defaults.Animal;
%  >> pars
%     struct with fields:
%        DefaultRecLoc
%        TankSaveLocDefault
%        ...
%
%  pars = nigeLab.defaults.Animal(par1,par2,...,parN);
%  >> [SpecialMeta,Delimiter] = nigeLab.defaults.Experiment(...
%                                'SpecialMeta','Delimiter');

%% Specify nigeLab.Animal class-related parameter defaults here
pars = struct;
pars.DefaultRecLoc = 'R:/';
pars.SaveLocDefault = 'P:/';
pars.FolderIdentifier = '.nigelAnimal';
pars.OnlyBlockFoldersAtAnimalLevel = true; % false if other kinds of folders exist there
pars.UnifyChildMask = true;  % Set false to allow different recordings to include unique channels

%% Name parsing: see '~/+defaults/Block.m' for detailed documentation
% This works the same way, but applies to Animal name
% pars.DynamicVarExp={'$AnimalID'};   % (FB)
pars.DynamicVarExp={'$SurgYear','$SurgNumber'}; % (MM)
pars.NamingConvention={'AnimalID'}; % (FB,MM)

pars.SpecialMeta = struct;
pars.SpecialMeta.SpecialVars = {};
pars.SpecialMeta.AnimalID.cat = '-'; % Concatenater (if used) for names
pars.SpecialMeta.AnimalID.vars = {'SurgYear','SurgNumber'}; % KUMC "standard"
% pars.SpecialMeta.AnimalID.vars = {'Project','SurgNumber'}; % KUMC "RC"

pars.Delimiter   = '-'; % delimiter for variables in ANIMAL name
pars.Concatenater = '-'; % concatenater for variables INCLUDED in ANIMAL name
% pars.VarExprDelimiter = {'_'}; % Delimiter for parsing "special" vars (FB)
pars.VarExprDelimiter = {'-','_'}; % (MM)
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

