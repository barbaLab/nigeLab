classdef nigelProgress < handle
% NIGELPROGRESS    Create a bar allowing graphical tracking of
%                  completion status via the bar progress.
%
%   bar = nigeLab.libs.nigelProgress('barName',jobObj,UserData);
%
%   bar  --  output handle to nigeLab.libs.nigelProgress object
%
%   name  --  char array that is descriptor of thing to monitor
%   job  --  Matlab job object
%   UserData  --  Any data to associate with the bar
%
%  PROPERTIES:
%     Parent - Parent (container) object
%     
%     Children - Cell array of Children objects, which is as follows:
%                 * prog_axes:        Axes containing progressbar
%                 * progname_label:   text "label"
%                 * progbar_patch:    patch that "grows" with progress
%                 * progpct_label:    text % as bar grows
%                 * progstatus_label: text status of task
%                 * progX_btn:        pushbutton uicontrol to cancel
%
%     UserData - Optional specified UserData that can be used for
%                indexing the task that is being tracked.
%
%  METHODS:
%     nigelProgress - Class constructor
   
   properties (Access = public, SetObservable = true)
      Position  double   % Position of "container" but updates graphics
   end

   properties (SetAccess = private, GetAccess = public)
      Name      char                          % Name of bar
      Parent    matlab.ui.container.Panel     % Parent Panel object
      Children  cell                          % Array of Child objects
      UserData
   end
   
   properties (Access = public, Hidden = true)
      idx
      job
      starttime
   end
   
   methods (Access = public)
      % Class constructor for NIGELPROGRESS class
      function bar = nigelProgress(parent,name,job,idx,UserData,starttime)
         % NIGELPROGRESS    Create a bar allowing graphical tracking of
         %                  completion status via the bar progress.
         %
         %   bar = nigeLab.libs.nigelProgress('barName',jobObj,UserData);
         %
         %   bar  --  output handle to nigeLab.libs.nigelProgress object
         %
         %   parent -- parent container
         %   name  --  char array that is descriptor of thing to monitor
         %   job  --  Matlab job object
         %   idx  --  index associated with this bar
         %   UserData  --  Any data to associate with the bar
         %   starttime  --  Start time (clock()) can be assigned optionally
         %
         %  bar = nigeLab.libs.nigelProgress(5);
         %  --> Return an empty column array of 5 nigelProgres bars
         
         %% Check input
         if nargin < 1
            bar = repmat(bar,0);
            return;
         end
         
         if nargin == 1
            if isnumeric(parent)
               dims = parent;
               if isscalar(dims)
                  dims = [dims, 1];
               end
               bar = repmat(bar,dims);
               return;
            elseif isa(parent,'nigeLab.libs.nigelPanel')
               parent = parent.Panel;
            end
         end
         
         if nargin < 2
            name = '';
         end
         
         if nargin < 3
            job = [];
         end
         
         if nargin < 4
            idx = 1;
         end
         
         if nargin < 5
            UserData = [];
         end
         
         if nargin < 6
            starttime = clock();
         end
         
         %% Assign basic properties
         bar.Name = name;
         bar.Parent = parent;
         bar.UserData = UserData;
         bar.Position = [0 0 1 1];
         
         bar.idx = idx;
         bar.job = job;
         bar.starttime = starttime;
         
         %% Build Children graphics
         bar.Children = cell(6,1);
         bar.Children{1} = axes(bar.Parent, ...
            'Units','Normalized',...
            'Position', [0.025 0.025 0.900 0.950], ...
            'XLim', [0 1], ...
            'YLim', [0 1], ...
            'Box', 'off', ...
            'ytick', [], ...
            'xtick', [],...
            'Tag','prog_axes',...
            'UserData',idx);
         
         bar.Children{2} = text(bar.Children{1},...
            0.01, 0.5, name, ...
            'HorizontalAlignment', 'Left', ...
            'FontUnits', 'Normalized', ...
            'FontSize', 0.7,...
            'Color',nigeLab.defaults.nigelColors('onsurface'),...
            'FontName','Droid Sans',...
            'Tag','progname_label');
         
         bar.Children{3} = patch(bar.Children{1}, ...
            'XData', [0.5 0.5 0.5 0.5], ...
            'YData', [0   0   1   1  ],...
            'FaceColor',nigeLab.defaults.nigelColors(1),...
            'Tag','progbar_patch');
         
         patch(bar.Children{1}, ...
            'XData', [0 0.5 0.5 0], ...
            'YData', [0 0   1   1],...
            'FaceColor',nigeLab.defaults.nigelColors('surface'),...
            'EdgeColor',nigeLab.defaults.nigelColors('surface'));
         
         bar.Children{4} = text(bar.Children{1},...
            0.99, 0.5, '0%', ...
            'HorizontalAlignment', 'Right', ...
            'FontUnits', 'Normalized', ...
            'FontSize', 0.7,...
            'FontName','Droid Sans',...
            'Tag','progpct_label');
         
         bar.Children{5} = text(bar.Children{1},...
            0.52, 0.5, '', ...
            'HorizontalAlignment', 'Left', ...
            'FontUnits', 'Normalized', ...
            'FontSize', 0.7,...
            'FontName','Droid Sans',...
            'Tag','progstatus_label');
         
         %%%% Design and plot the cancel button
         % It goes on bar.Parent instead of on the axes object         
         bar.Children{6} = uicontrol(bar.Parent,...
            'Style','pushbutton',...
            'Units','Normalized',...
            'Position', [0.925 0.025 0.050 0.950],...
            'BackgroundColor',nigeLab.defaults.nigelColors(0.1),...
            'ForegroundColor',nigeLab.defaults.nigelColors(3),...
            'String','X',...
            'Tag','progX_btn');
      end
      
      % Things to do on delete function
      function delete(bar)
         % DELETE  Additional things to delete when 'delete' is called
         
         delete(bar.Parent);
         
      end
      
      % Return child object based on tag
      function h = getChild(bar,tag,propName)
         % GETCHILD  Return child object based on tag
         %
         %  h = bar.getChild('tag');
         %
         %  tag  --  char array. can be
         %           * prog_axes:        Axes containing progressbar
         %           * progname_label:   text "label"
         %           * progbar_patch:    patch that "grows" with progress
         %           * progpct_label:    text % as bar grows
         %           * progstatus_label: text status of task
         %           * progX_btn:        pushbutton uicontrol to cancel
         
         switch lower(tag)
            case {'prog_axes','axes','a','ax','prog','container'}
               h = bar.Children{1};
            case {'name','progname_label','progname'}
               h = bar.Children{2};
            case {'progx_btn','btn','x','xbtn'}
               h = bar.Children{6};
            case {'status','progstatus_label','progstatus'}
               h = bar.Children{5};
            case {'progbar_patch','patch','progbar','bar'}
               h = bar.Children{3};
            case {'progpct_label','pct','progpct'}
               h = bar.Children{4};
            otherwise
               error(['nigeLab:' mfilename ':tagMismatch'],...
                  'Could not find Child object for tag: %s',tag);
         end
         
         % If value is requested, return that instead
         if nargin > 2
            if isprop(h,propName)
               h = h.(propName);
            else
               error(['nigeLab:' mfilename ':propMismatch'],...
                  'Could not find Property (%s) for %s Child Object.',...
                  propName,tag);
            end
         end
      end
      
      % Set child object property based on tag
      function h = setChild(bar,tag,propName,propVal)
         % SETCHILD  Set property of child object based on tag
         %
         %  bar.setChild('tag','propName',propVal);
         %
         %  tag  --  char array. can be
         %           * prog_axes:        Axes containing progressbar
         %           * progname_label:   text "label"
         %           * progbar_patch:    patch that "grows" with progress
         %           * progpct_label:    text % as bar grows
         %           * progstatus_label: text status of task
         %           * progX_btn:        pushbutton uicontrol to cancel
         
         switch lower(tag)
            case {'prog_axes','axes','a','ax','prog','container'}
               h = bar.Children{1};
            case {'name','progname_label','progname'}
               h = bar.Children{2};
            case {'progx_btn','btn','x','xbtn'}
               h = bar.Children{6};
            case {'status','progstatus_label','progstatus'}
               h = bar.Children{5};
            case {'progbar_patch','patch','progbar','bar'}
               h = bar.Children{3};
            case {'progpct_label','pct','progpct'}
               h = bar.Children{4};
            otherwise
               error(['nigeLab:' mfilename ':tagMismatch'],...
                  'Could not find Child object for tag: %s',tag);
         end
         if isprop(h,propName)
            h.(propName) = propVal;
         else
            error(['nigeLab:' mfilename ':propMismatch'],...
               'Could not find Property (%s) for %s Child Object.',...
               propName,tag);
         end
      end

      % Update status
      function updateStatus(bar,str)
         % UPDATESTATUS  Update status string
         %
         %  bar.updateStatus('statusText');
         
         bar.setChild('status','String',str);
      end
      
   end
   
   
end