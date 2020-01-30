function index = parseVidFileName(blockObj,fName)
%PARSEVIDFILENAME  Get video file info from video file
%
%  index = blockObj.parseVidFileName(fName);
%
%  fName    :     If path is path/file.ext, then this is 'file.ext'
%
%  --> If no outputs are requested, then it uses the value in fName to add
%      a row to the blockObj.Meta.Video table of video metadata.

[n,metaFields,parsedVars] = checkValidConfig(fName,blockObj.Pars.Video);
meta = struct;
for ii = 1:n
   meta.(metaFields{ii}) = parsedVars(ii);
end
% Match key to parent block
meta.Key = {sprintf('%s-%03g',...
   getKey(blockObj,'Public'),size(blockObj.Meta.Video,1))};
blockObj.Meta.Video = [blockObj.Meta.Video; struct2table(meta)];
index = size(blockObj.Meta.Video,1); % Allows tracking of "row"

   % Helper functions
   % Checks for valid configuration based on number & order of tokens/pars
   function [n,mVar,pVar] = checkValidConfig(f,pars)
      %CHECKVALIDCONFIG  Checks if parameters configuration is valid based
      %                    on the number and order of tokens parsed from
      %                    vars.
      %
      %  [n,mVar,pVar] = checkValidConfig(f,pars);
      %  
      %  f : Filename (If path is path/file.ext, then this is 'file.ext')
      %  pars : blockObj.Pars.Video parameters struct
      %
      %  n : Number of elements in `pvar`
      %  mVar : Cell array of meta variable names (fields of .Meta.Video)
      %  pVar : "Split" cell array of tokens (char arrays) based on
      %           delimited elements of video file name. 
      %
      %  --> Check based on presence of pars.CameraSourceVar, and index of
      %      token corresponding to pars.MovieIndexVar (based on
      %      order of elements in pars.DynamicVars), if there are enough
      %      tokens parsed from the movie filename.
      
      [~,str,~] = fileparts(f);
      pVar = strsplit(str,pars.Delimiter); % "parsed vars"
      n = numel(pVar);
      mVar = cellfun(@(x)x(2:end),pars.DynamicVars,... % "meta vars"
                     'UniformOutput',false);
      m = numel(mVar);
      if ~isempty(pars.MovieIndexVar)
         midx = ismember(mVar,pars.MovieIndexVar); % Index within DynamicVars
         if sum(midx)<1 % Check that movieIndexVar is correctly-configured
            error(['nigeLab:' mfilename ':BadConfig'],...
               ['Block.Pars.Video.MovieIndexVar is specified,' ...
               'but was not recovered from Block.Pars.Video.DynamicVars\n' ...
               '->\t(Double-check configuration in ~/+defaults/Videos.m)']);
         elseif sum(midx) > 1
            error(['nigeLab:' mfilename ':BadConfig'],...
                  ['Block.Pars.Video.MovieIndexVar is ambiguous\n' ...
                  '->\t(%g instances found in Block.Pars.Video.DynamicVars)\n'],...
                  sum(midx));
         else
            % Make sure that indexing variable is a "numeric" token
            if isnan(str2double(pVar{midx}))
               error(['nigeLab:' mfilename ':BadConfig'],...
                  ['Block.Pars.Video.MovieIndexVar does not correspond ' ...
                  'to an indexing token (%s)\n' ...
                  '->\t(Should be a "numeric" token)\n'],pVar{midx});
            end
         end
         midx = find(midx,1,'first');
      else
         midx = -inf;
      end
      % Do the same if there is a .CameraSourceVar (may not be)
      if ~isempty(pars.CameraSourceVar)
         cidx = ismember(mVar,pars.CameraSourceVar);
         if sum(cidx)<1 
            error(['nigeLab:' mfilename ':BadConfig'],...
               ['Block.Pars.Video.CameraSourceVar is specified, ' ...
               'but it is not included in Block.Pars.Video.DynamicVars.\n' ...
               '->\t(Double-check configuration in ~/+defaults/Videos.m)']);
         elseif sum(cidx)>1
            error(['nigeLab:' mfilename ':BadConfig'],...
               ['Block.Pars.Video.CameraSourceVar is ambiguous\n' ...
               '->\t(%g instances found in Block.Pars.Video.DynamicVars)\n'],...
               sum(cidx));
         end
         cidx = find(cidx,1,'first');
      else
         cidx = -inf;
      end
      if m > n % More meta variables than filename tokens
         % If index of this variable is outside token range throw error
         if midx > n
            error(['nigeLab:' mfilename ':BadConfig'],...
               ['Block.Pars.Video.MovieIndexVar token is out of range\n' ...
                '\t->(Needs at least %g tokens but only recovered %g from ' ...
                'movie filename [%s])\n'],midx,n,f);
         end
         % If CameraSourceVar is not empty, then check that it is not out
         % of range.
         if cidx > n
            error(['nigeLab:' mfilename ':BadConfig'],...
               ['Block.Pars.Video.CameraSourceVar token is out of range\n' ...
                '\t->(Needs at least %g tokens but only recovered %g from ' ...
                'movie filename [%s])\n'],cidx,n,f);
         end
      end
   end
end