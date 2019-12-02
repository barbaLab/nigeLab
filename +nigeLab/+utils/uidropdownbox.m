function [string_out, index_out] = uidropdownbox(title_str,prompt,opts,forceSelection)
% UIDROPDOWNBOX    Create a dropdown box to let user select a string
%
%   [string_out,index_out] = nigeLab.utils.uidropdownbox(title_str,prompt,opts)
%     * If no output selected, string_out is 'none' and index_out is NaN *
%
%   --------
%    INPUTS
%   --------
%    title_str  :       String or char array:
%                       --> Name of window for dialog box
%                       Cell array:
%                       --> title_str{1} == Name of window for dialog box
%                       --> title_str{2} == "Sub-header" (name of panel)
%
%     prompt    :       String or char array:
%                       --> Instructions displayed in dialog box.
%                          --> For multi-line format, call as a cell array.
%                              Each cell element starts on a new line
%                              within the prompt textbox.
%
%    opts       :       Cell array:
%                       --> Each element is a char array or string, giving
%                           the list item for each row of the popup list.
%
%  forceSelection :     (Optional) Default: true
%                       --> If specified as false, then the user is no
%                           longer required to make a selection from the
%                           listbox in order for the interface to not
%                           return 'none' and NaN for the index. For
%                           example, this is useful if the default will
%                           probably be used almost every time.
%
%   --------
%    OUTPUT
%   --------
%    string_out :       String; corresponds to the user-selected string.
%
%    index_out  :       Integer; corresponds to index of selected string.


% Check input
if nargin < 4
   forceSelection = true;
end

if ~iscell(opts)
   opts = {opts};
end

if ~iscell(title_str)
   title_str = {title_str};
elseif numel(title_str) < 2
   title_str = [title_str; title_str];
end

% Create handle to store data and build graphics
if forceSelection
   h = nigeLab.utils.uiHandle('str','none','ind',nan);
else
   h = nigeLab.utils.uiHandle('str',opts{1},'ind',1);
end

        
fig = figure('Name',title_str{1}, ...
           'Units', 'Normalized', ...
           'Position',[0.3 0.5 0.3 0.3],...
           'MenuBar','none',...
           'ToolBar','none',...
           'NumberTitle','off');

p = nigeLab.libs.nigelPanel(fig,...
            'String',title_str{2},...
            'Tag','uidropdownbox',...
            'Units','normalized',...
            'Position',[0 0 1 1],...
            'Scrollable','off',...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('tertiary'),...
            'TitleColor',nigeLab.defaults.nigelColors('ontertiary'));
        
prompt_text = uicontrol('Style','text',...
           'Units','Normalized', ...
           'Position',[0.2 0.775 0.6 0.20],...
           'FontSize', 22, ...
           'FontWeight','bold',...
           'FontName','DroidSans',...
           'BackgroundColor',nigeLab.defaults.nigelColors('surface'),...
           'ForegroundColor',nigeLab.defaults.nigelColors('tertiary'),...
           'String',prompt);
p.nestObj(prompt_text);

str_box = uicontrol('Style','popupmenu',...
           'Units', 'Normalized', ...
           'Position',[0.05 0.4 0.9 0.30],...
           'FontSize', 16, ...
           'FontName','DroidSans',...
           'String',opts,...
           'Callback',{@assign_str,h});
        
p.nestObj(str_box);

submit_btn = uicontrol('Units', 'Normalized', ...
          'Position',[0.4 0.1 0.2 0.15],...
          'FontSize', 22, ...
          'FontWeight','bold',...
          'FontName','DroidSans',...
          'String','SUBMIT',...
          'BackgroundColor',nigeLab.defaults.nigelColors('tertiary'),...
          'ForegroundColor',nigeLab.defaults.nigelColors('ontertiary'),...
          'Callback',@submit_selection);
p.nestObj(submit_btn);
       
% Callback functions
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


% Assign output after dialog closes
waitfor(fig);
[string_out,index_out] = get(h,'str','ind');
delete(h);
clear('h');

end