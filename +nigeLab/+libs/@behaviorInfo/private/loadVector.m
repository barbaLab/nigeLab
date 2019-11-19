function var = loadVector(F,defVal,varNum,warnFlag,verbose)
%% LOADVECTOR    Load a Vector variable without needing specific name
%
%  var = LOADVECTOR(F);
%  var = LOADVECTOR(F,defVal);
%  var = LOADVECTOR(F,defVal,varNum);
%  var = LOADVECTOR(F,defVal,varNum,warnFlag);
%  var = LOADVECTOR(F,defVal,varNum,warnFlag,verbose);
%
%  --------
%   INPUTS
%  --------
%     F           :     File struct (from 'dir') for a given file.
%
%   defVal        :     (Optional) Default scalar value if file is not
%                                   found. If not specified, default is
%                                   NaN.
%
%   varNum        :     (Optional) Index of variable to load. Use this if
%                                   you know the behavior of the file to be
%                                   loaded, for example if you know the 2nd
%                                   indexed variable name will always be
%                                   the desired variable to load. Not
%                                   recommended.
%
%  warnFlag       :     (Optional) flag to suppress warnings. If not
%                                 specified, defaults to true and warns
%                                 user if there are multiple variables in a
%                                 given file to be loaded. Can be specified
%                                 as false if you know the behavior of
%                                 loading a particular file with multiple
%                                 variables, but not recommended.
%
%  verbose        :     (Optional) bool flag. Default is false. Set true to
%                                print indicator text to Command Window.
%
%  --------
%   OUTPUT
%  --------
%     var         :     N x 1 vector of N samples. Basically the utility is
%                       that you don't have to specify the fieldname, this
%                       will automatically figure out what the variable is
%                       called and just load it.
%
% By: Max Murphy  v1.0   09/03/2018  Original version (R2017b)

%% PARSE INPUT
% Default of whether to display issues to UI
if nargin < 5
   verbose = false;
end

% Default to warning user about multiple variables
if nargin < 4
   warnFlag = true;
end

% Default to using index 1
if nargin < 3
   varNum = 1;
end

% Default value if no file
if nargin < 2
   defVal = nan;
end

%% CHECK FOR FILE EXISTENCE
fname = fullfile(F.folder,F.name);
if exist(fname,'file') == 0
   if verbose
      fprintf(1,'->\t%s not found.\n',F.name);
   end
   var = defVal;
   return;
end

%% LOAD FILE AND GET VARIABLE NAME(S)
tmp = load(fname);
in = fieldnames(tmp);


%% (OPTIONAL) WARN USER IF MULTIPLE VARIABLES IN FILE
if warnFlag && verbose
   % If there is more than one vector, warn user that they might not be
   % loading the one they hoped...
   k = numel(in);
   if k > 1
      warning('%d variables in %s. Loading %s...',k,F.name,in{varNum});
   end
end

%% PICK 1 VARIABLE TO RETURN
var = tmp.(in{varNum});
% Check if it doesn't look like a vector
if (numel(var) < 2) && verbose
   warning('Only 1 element in %s. Is this what you meant to load?',...
      in{varNum});
end

% Reformat it for table orientation (N x 1)
N = numel(var);
var = reshape(var,N,1);

end