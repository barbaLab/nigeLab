function h = printWarningLoop(warningParams)
%% PRINTWARNINGLOOP  Warning function to count down before **SOMETHING**
%
%  Default behavior is to warn user something is happening and count down
%  for 3 seconds, giving the opportunity to cancel (manually via ctrl+c in
%  Command Window) prior to continuing with execution of the script.
%
%  Input: warningParams (struct; optional)
%  --> Fields
%     --> 'n' : Default 10 (# countdown loops)
%     --> 'counter_color' : 'UnterminatedStrings' 
%           (see nigeLab.utils.cprintf)
%     --> 'counter_duration' : Duration of each loop iteration (seconds;
%                                default: 1)
%     --> 'warning_string' : '-->\tProceeding in ';
%     --> 'warning_color' : 'Blue';
%     --> 'fig_visible' : 'off' (visibility of figure h output)
%     --> 'fig_key_press_fcn' : Empty function handle to key press for h
%     --> 'fig_create_fcn' : Empty function handle to h CreateFcn
%
%  Output: h
%     Returns a handle to an (invisible) figure that is deleted when
%      countdown execution is completed. So, for example, a process waiting
%      on this could use wait(h) prior to terminating.

%%

% Get default parameters
p = getDefaultWarningParams();

% Potentially replace parameters if input argument is specified
if nargin > 0
   f = fieldnames(warningParams);
   for iF = 1:numel(f)
      if isfield(p,f{iF})
         p.(f{iF}) = warningParams.(f{iF});
      else
         warning('%s is not a valid field of warningParams.',...
            warningParams.(f{iF}));
      end
   end
end

h = figure('Name','printWarningLoop Object Handle',...
   'Visible',p.fig_visible,...
   'WindowKeyPressFcn',p.fig_key_press_fcn,...
   'CreateFcn',p.obj_create_fcn);

% Print a warning and indicate that timer is counting down
fprintf(1,' \n');
nigeLab.utils.cprintf(p.warning_color,p.warning_string);
nigeLab.utils.cprintf(p.counter_color,'%02gs\n',p.n);

% Loop through counter and pause on each iteration
for i = p.n:-1:1
   nigeLab.utils.cprintf(p.counter_color,'\b\b\b\b%02gs\n',i);
   pause(p.counter_duration);
end

   function warningParams_ = getDefaultWarningParams()
      warningParams_ = struct;
      warningParams_.n = 3;
      warningParams_.counter_color = 'UnterminatedStrings';
      warningParams_.counter_duration = 1;
      warningParams_.warning_string = '-->\tProceeding in ';
      warningParams_.warning_color = 'Blue';
      warningParams_.fig_visible = 'off';
      warningParams_.fig_key_press_fcn = [];
      warningParams_.fig_create_fcn = [];
      
   end

end