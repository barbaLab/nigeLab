function [string_out, index_out] = uidropdownbox(TITLE,PROMPT,CELL_OPTS)
%% UIDROPDOWNBOX    Create a dropdown box to let user select a string
%
%   [string_out,index_out] = UIDROPDOWNBOX(TITLE,PROMPT,CELL_OPTS)
%     * If no output selected, string_out is 'none' and index_out is NaN *
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
%                   v2.0    11/30/2019  Added nigelColors defaults

%% DEFINE HANDLES FOR PASSING ARGUMENTS

h = nigeLab.utils.uiHandle('str','none','ind',nan);

%% CREATE DIALOG BOX
        
fig = figure('Name',TITLE, ...
           'Units', 'Normalized', ...
           'Position',[0.3 0.5 0.3 0.3],...
           'MenuBar','none',...
           'ToolBar','none',...
           'NumberTitle','off');

p = nigeLab.libs.nigelPanel(fig,...
            'String',TITLE,...
            'Tag','uidropdownbox',...
            'Units','normalized',...
            'Position',[0 0 1 1],...
            'Scrollable','off',...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
        
prompt_text = uicontrol('Style','text',...
           'Units','Normalized', ...
           'Position',[0.2 0.775 0.6 0.20],...
           'FontSize', 16, ...
           'BackgroundColor',nigeLab.defaults.nigelColors('surface'),...
           'ForegroundColor',nigeLab.defaults.nigelColors('primary'),...
           'String',PROMPT);
p.nestObj(prompt_text);

str_box = uicontrol('Style','popupmenu',...
           'Units', 'Normalized', ...
           'Position',[0.05 0.4 0.9 0.30],...
           'FontSize', 16, ...
           'String',CELL_OPTS,...
           'Callback',{@assign_str,h});
        
p.nestObj(str_box);

submit_btn = uicontrol('Units', 'Normalized', ...
          'Position',[0.4 0.1 0.2 0.15],...
          'FontSize', 16, ...
          'String','SUBMIT',...
          'BackgroundColor',nigeLab.defaults.nigelColors('secondary'),...
          'ForegroundColor',nigeLab.defaults.nigelColors('onsecondary'),...
          'Callback',@submit_selection);
p.nestObj(submit_btn);
       
%% DEFINE DIALOG FUNCITONS
   function assign_str(src,~,h)
      % ASSIGN_STR  Callback for when popupmenu is clicked
      %
      %  str_box.Callback = {@assign_str,h}; h is nigeLab.libs.uiHandle
      %                                      class object that holds all
      %                                      the data.
      
      set(h,'str',src.String{src.Value},'ind',src.Value);
   end

   function submit_selection(src,~)
      % SUBMIT_SELECTION  Callback that executes when "submit" button is
      %                   clicked. It simply destroys parent
      %                   nigeLab.libs.nigelPanel object and current
      %                   figure.
      
      delete(src.Parent);
      delete(gcf);
   end


%% WAIT FOR DIALOG TO CLOSE AND ASSIGN OUTPUT
waitfor(fig);
[string_out,index_out] = get(h,'str','ind');
delete(h);
clear('h');

end