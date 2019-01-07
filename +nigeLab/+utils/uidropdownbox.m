function [string_out, index_out] = uidropdownbox(TITLE,PROMPT,CELL_OPTS)
%% UIDROPDOWNBOX    Create a dropdown box to let user select a string
%
%   [string_out,index_out] = UIDROPDOWNBOX(TITLE,PROMPT,CELL_OPTS)
%
%   --------
%    INPUTS
%   --------
%     TITLE     :       String; name of window for modal dialog box.
%
%     PROMPT    :       String; instructions displayed in dialog box.
%                      -> For multi-line format, use:
%                         uidropdownbox( __ ,'PROMPT',{'line1';'line2'...})
%
%     CELL_OPTS :       Cell; cell vector of strings to list as options for
%                             dropdown of dialog box.
%
%   --------
%    OUTPUT
%   --------
%    string_out :       String; corresponds to the user-selected string.
%
%    index_out  :       Integer; corresponds to index of selected string.
%
% By: Max Murphy    v1.0    05/01/2017  Original version (R2017a)
%                   v1.1    10/02/2017  Added 'index_out' option.
%                   v1.2    01/05/2018  Improved handling of cases where
%                                       dialog box is closed without making
%                                       a selection.

%% DEFINE HANDLES FOR PASSING ARGUMENTS
handles.str = CELL_OPTS{1};
handles.ind = 1;

%% CREATE DIALOG BOX
        
d = dialog('Name',TITLE, ...
           'Units', 'Normalized', ...
           'Position',[0.3 0.5 0.3 0.3],...
           'UserData',struct('str',CELL_OPTS{1},'ind',nan),...
           'DeleteFcn',@close_window);

uicontrol('Parent',d,...
           'Style','text',...
           'Units','Normalized', ...
           'Position',[0.2 0.775 0.6 0.20],...
           'FontSize', 16, ...
           'String',PROMPT);

str_box = uicontrol('Parent',d,...
           'Style','popupmenu',...
           'Units', 'Normalized', ...
           'Position',[0.05 0.4 0.9 0.30],...
           'FontSize', 16, ...
           'String',CELL_OPTS,...
           'Callback',@assign_str);

uicontrol('Parent',d,...
          'Units', 'Normalized', ...
          'Position',[0.4 0.1 0.2 0.15],...
          'FontSize', 16, ...
          'String','SUBMIT',...
          'Callback',@submit_selection);
       
%% DEFINE DIALOG FUNCITONS
   function assign_str(src,~)
      f = src.Parent;
      f.UserData.str = src.String{src.Value};
      f.UserData.ind = src.Value;
   end

   function submit_selection(src,~)
      f = src.Parent;
      f.UserData.str = str_box.String{str_box.Value};
      f.UserData.ind = str_box.Value;
      delete(f);
   end

   function close_window(src,~)
      handles.str = src.UserData.str;
      handles.ind = src.UserData.ind;
   end

%% WAIT FOR DIALOG TO CLOSE AND ASSIGN OUTPUT
waitfor(d);
string_out = handles.str;
index_out = handles.ind;

end