function s = addStructField(s,varargin)
%% ADDSTRUCTFIELD   Add field(s) to an existing struct.
%
%   s = ADDSTRUCTFIELD(s,field_1,field_2,...field_K)
%
%   --------
%    INPUTS
%   --------
%      s        :   N x 1 struct array that you want to append fields to.
%
%    field_i    :   A variable that you want to add as field in struct s.
%                   Because s is in array format, you can't do this easily
%                   because The Mathworks wants everyone to use tables
%                   instead of structs or something, I don't know.
%
%   --------
%    OUTPUT
%   --------
%      s        :   Same as input struct array, but with appended fields.
%
% By: Max Murphy    v1.0    08/15/2017  Original version (R2017a)

%% OPTIONS
verbose = false;

%% GET EXISTING FIELDS
orig = fieldnames(s);
for iF = 1:numel(orig)
   eval([orig{iF} '={s.(orig{iF})};']);
   eval([orig{iF} '= reshape(' orig{iF} ',numel(' orig{iF} '),1);']);
end

%% GET ALL FIELDS
N = numel(s);
allfields = orig;
if verbose
   fprintf(1,'Struct: %s\n*\t*\t*\t*\t*\t*\t*\t*\t*\t*\t*\n',inputname(1)); %#ok<*UNRCH>
end
for iV = 1:numel(varargin)
   f = inputname(iV+1);
   
   if numel(varargin{iV})==N
      allfields = [allfields; f];  %#ok<*AGROW>
      if verbose
         fprintf(1,'-->\tAdding field: %s (%s)\n',f,class(varargin{iV}));
      end
      eval([f '=varargin{iV};']);
      eval([f '= reshape(' f ',numel(' f '),1);']); % Get proper dim.
      eval(['temp=' f ';']);
      eval([f ' = cell(N,1);']);
      for iN = 1:N
         eval([f '{iN}=temp(iN);']);
      end
   elseif size(varargin{iV},1)==N
      allfields = [allfields; f];  
      if verbose
         fprintf(1,'-->\tAdding field: %s (%s)\n',f,class(varargin{iV}));
      end
      eval([f '=varargin{iV};']);
      eval(['temp=' f ';']);
      eval([f ' = cell(N,1);']);
      for iN = 1:N
         eval([f '{iN}=temp(iN,:);']);
      end
   elseif size(varargin{iV},2)==N
      allfields = [allfields; f]; 
      if verbose
         fprintf(1,'-->\tAdding field: %s (%s)\n',f,class(varargin{iV}));
      end
      eval([f '=varargin{iV};']);
      eval(['temp=' f ';']);
      eval([f ' = cell(N,1);']);
      for iN = 1:N
         eval([f '{iN}=temp(:,iN).'';']);
      end
   else
      allfields = [allfields; f];
      if verbose
         fprintf(1,'-->\tAdding field: %s (%s)\n',f,class(varargin{iV}));
      end
      eval([f '=varargin{iV};']);
   end
end

%% MAKE STRUCT WITH THESE FIELDS
str = ['''' allfields{1} ''',' allfields{1}];
for iF = 2:numel(allfields)
   str = strjoin({str,...
      ['''' allfields{iF} ''',' allfields{iF}]}...
      ,',');
end
eval(['s=struct(' str ');']);

end