function varargout = buildWorkerConfigScript(queueMode,varargin)
%BUILDWORKERCONFIGSCRIPT  Programmatically creates a worker config file
%
%  configFile = nigeLab.utils.buildWorkerConfigScript();
%  --> defaults to 'fromRemote' queueMode (i.e. FB method)
%     --> Used if running from T:\Scripts_Circuits
%  configFile = nigeLab.utils.buildWorkerConfigScript('fromLocal',varargin);
%     --> Used if running from local repository that is not on same server
%         as the remote location, but the data and a clone of the
%         repository are set up on the remote location. (i.e. MM method)
%     --> varargin{1}: The full file path of the remote repo to add to path
%
%  configFile  --  Char array that is the full filename (including path) of
%                    the script to attach to the job and run on the worker.

%% Imports and Defaults
import nigeLab.defaults.Tempdir nigeLab.utils.getNigelPath
CONFIG_SCRIPT_NAME = 'configW.m'; % Script that adds path of repo
WRAPPER_FCN_NAME = 'qWrapper.m';  % "Wrapper" for remote queue execution

%%
if nargin < 1
   queueMode = 'fromLocal';
end

if ~ischar(queueMode)
   error(['nigeLab:' mfilename ':BadInputType2'],...
      'Unexpected class for ''queueMode'' input: %s\n',class(queueMode));
end

configFile = fullfile(Tempdir,CONFIG_SCRIPT_NAME);
switch lower(queueMode)
   case {'remote','fromremote'}
      % Just makes sure nigeLab is added to path (didn't work for MM)
      % This works if the method is queued FROM repo on remote location:
      p = getNigelPath('UNC'); 
      if exist(configFile,'file')~=0
         delete(configFile);
      end
      fid = fopen(configFile,'w');
      fprintf(fid,'%%CONFIGW  Programmatically-generated path adder\n');
      fprintf(fid,'%%\n');
      fprintf(fid,'%%\tconfigW; Add nigeLab remote repo to worker path\n');
      addAutoSignature(fid,sprintf('nigeLab.utils.%s',mfilename));
      fprintf(fid,'%%%% Add remote nigeLab repository.\n');
      fprintf(fid,'addpath(''%s''); %% Parsed repo location\n\n',p);
      fprintf(fid,'%%%% Import getNigelPath to make sure we add path\n');
      fprintf(fid,'import nigeLab.utils.getNigelPath\n'); 
      fprintf(fid,'p = getNigelPath(''UNC''); %% Return worker path\n');
      fprintf(fid,'addpath(p); %% Add "imported" path');
      fclose(fid);
      varargout = {configFile};
   case {'local','fromlocal'}
      % "Wrap" everything in a script that is executed by the worker,
      % instead of the `doAction`
      p = varargin{1};
      operation = varargin{2};
      
      if exist(configFile,'file')~=0
         delete(configFile);
      end
      fid = fopen(configFile,'w');
      fprintf(fid,'%%CONFIGW  Programmatically-generated path adder\n');
      fprintf(fid,'%%\n');
      fprintf(fid,'%%\tconfigW; Add nigeLab remote repo to worker path\n');
      addAutoSignature(fid,sprintf('nigeLab.utils.%s',mfilename));
      fprintf(fid,'%%%% Add remote nigeLab repository.\n');
      fprintf(fid,'addpath(''%s''); %% Fixed remote repo location\n\n',p);
      fprintf(fid,'%%%% Import getNigelPath to make sure we add path\n');
      fprintf(fid,'import nigeLab.utils.getNigelPath\n'); 
      fprintf(fid,'p = getNigelPath(''UNC''); %% Return worker path\n');
      fprintf(fid,'addpath(p); %% Add "imported" path');
      fclose(fid);
      
      wrapperFile = fullfile(pwd,WRAPPER_FCN_NAME);
      if exist(wrapperFile,'file')~=0
         delete(wrapperFile);
      end
      fid = fopen(wrapperFile,'w');
      fprintf(fid,'function qWrapper(targetFile)\n');
      fprintf(fid,'%%QWRAPPER  Programmatically-generated fcn wrapper\n');
      fprintf(fid,'%%\n');
      fprintf(fid,'%%\tqWrapper(targetFile); Run nigelLab on target\n');
      addAutoSignature(fid,sprintf('nigeLab.utils.%s',mfilename));
      fprintf(fid,'%%%% Add remote nigeLab repository.\n');
      fprintf(fid,'configW; %% Also auto-gen''d\n\n');
      fprintf(fid,'%%%% Attempt to load target Block.\n');
      fprintf(fid,'%% Do some error-checking\n');
      fprintf(fid,'try\n\t');
      fprintf(fid,'blockObj = nigeLab.Block.remoteLoad(targetFile);\n');
      fprintf(fid,'catch me\n\t');
      fprintf(fid,['if strcmp(me.identifier,' ...
                   '''nigeLab:loadRemote:ObjectNotFound'')\n\t\t']);
      fprintf(fid,'error([''nigeLab:'' mfilename '':BadLoad''],...\n\t\t');
      fprintf(fid,'\t''nigeLab not found (@ %%s)\\n'',pwd);\n\t');
      fprintf(fid,'else\n\t\t');
      fprintf(fid,'rethrow(me);\n\t');
      fprintf(fid,'end %% end compare identifier\n');
      fprintf(fid,'end %% end try load ... catch\n\n');
      fprintf(fid,'%%%% Now Block is successfully loaded. Run method.\n');
      fprintf(fid,'blockObj.%s(); %% Runs queued `doAction`\n',operation);
      fprintf(fid,'end');
      fclose(fid);
      
      varargout = cell(1,2);
      varargout{1} = configFile;
      varargout{2} = wrapperFile;
   otherwise
      error(['nigeLab:' mfilename ':UnexpectedString'],...
         ['Unexpected case: %s\n' ...
          '(should be ''fromRemote'' or ''fromLocal'')\n'],...
         queueMode);
end

   % Add generator function name and date/time of creation to
   % programmatically-generated function or script
   function addAutoSignature(fid,fname)
      %ADDAUTOSIGNATURE  Helper function to add generator name & datetime
      fprintf(fid,'%%\n');
      fprintf(fid,'%% Auto-generated by %s:\n',fname);
      fprintf(fid,'%%\t\t%s\n\n',char(datetime));
   end

end