function varargout = Experiment(varargin)
% EXPERIMENT   Template for initializing experimental metadata notes
%              Importantly, the default behavior for choosing an
%              acquisition system is set here, in case one of the standard
%              initializations goes wrong.
%
%  pars = nigeLab.defaults.Experiment;
%  >> pars
%     struct with fields: 
%        Folder
%        File 
%        ...     
%
%  pars = nigeLab.defaults.Experiment(par1,par2,...,parN);
%  >> [User,Delimiter] = nigeLab.defaults.Experiment('User','Delimiter');

%% Specify Experiment-related parameter defaults here
pars = struct;
[pars.Folder,~,~] = fileparts(mfilename('fullpath'));
pars.File = 'Experiment.txt';
pars.Delimiter = '|';
pars.StandardPortNames = {'A','B','C','D'};
pars.DefaultAcquisitionSystem = 'RHD';  % Important if things go wrong
pars.SupportedFormats = {'.rhs','.rhd','tdt'};
pars.User = 'MM'; % Default user

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