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
pars.NamingConvention={'$AnimalID'};   % (FB)
% pars.DynamicVarExp={'$SurgYear','$SurgNumber'}; % (MM)
% pars.NamingConvention={'AnimalID'}; % (FB,MM)

pars.SpecialMeta = struct;
pars.SpecialMeta.SpecialVars = {}; % (FB)
% pars.SpecialMeta.SpecialVars = {'AnimalID'}; % (MM)
pars.SpecialMeta.AnimalID.cat = '-'; % Concatenater (if used) for names
% pars.SpecialMeta.AnimalID.vars = {'SurgYear','SurgNumber'}; % KUMC "standard"
% pars.SpecialMeta.AnimalID.vars = {'Project','SurgNumber'}; % KUMC "RC"

pars.Delimiter   = '_'; % delimiter for variables in ANIMAL name
pars.Concatenater = '-'; % concatenater for variables INCLUDED in ANIMAL name
pars.VarExprDelimiter = {'_'}; % Delimiter for parsing "special" vars (FB)
% pars.VarExprDelimiter = {'-','_'}; % (MM)
pars.IncludeChar='$'; % Delimiter for INCLUDING vars in name
pars.DiscardChar='~'; % Delimiter for excluding vars entirely (don't keep in meta either)

%% Many animals in one block 
%
% Modern recording amplifiers usually have the capabilities to record from
% many channels  simultaneously. This can be exploited to record from many
% animals simultaneously and save eveything in only one datafile. 
% You can signal this to nigel by interposing the here defined character
% between different animal names in the AnimalID field of the recording
% file
%
% Example 
% R18-68&&R18-69
pars.MultiAnimalsChar='&&';
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

