function [string_out,group_out,index_out] = uidropdownradiobox(title_str,prompt,opts,forceSelection)
% UIDROPDOWNRADIOBOX    Create a dropdown box to let user select a string.
%                          Selection options change depending on which
%                          radio button is toggled. Returns the char array
%                          returning to the selected list item, as well as
%                          the char array corresponding to the selected
%                          radio toggle button.
%
%   [string_out,group_out,index_out] = nigeLab.utils.uidropdownradiobox(title_str,prompt,opts)
%     * If no output selected, string_out is 'none' and index_out is NaN *
%
%  Example usage:
%  % Define inputs
%  title_str = {'Radio DropDown Test'; 
%               'Button Panel Label'};
%  prompt_str = {'Selection Options: A'; 
%                'Selection Options: B'; 
%                'Selection Options: C'};
%  opts = {{'value','array'},                   'A) Original'; ...
%          {'a','b','c','d'},                   'B) New'; ...
%          {'good','better','fantastic','best'},'C) Best Choices'};
%
%  [test_str,test_group,test_idx] = nigeLab.utils.uidropdownradiobox(...
%     title_str,...
%     prompt_str,...
%     opts)
%
%   --------
%    INPUTS
%   --------
%   title_str     :     Char array; name of window for dialog box.
%                       or
%                       Cell array: 
%                       --> title_str{1} == name of figure; 
%                       --> title_str{2} == name of radio button group
%
%    prompt       :     Char array; prompt for selection above popup box
%                       or
%                       Cell array: 
%                       --> Each element is a string or char array that
%                           defines the prompt string when the
%                           corresponding radio button is ticked.
%                         
%
%     opts        :     Cell array of cell arrays:
%                       --> Elements of opts(:,1) correspond to cell arrays
%                          --> Elements of opts{k,1}(:,1) are either string
%                              or char arrays that define the list of
%                              prompts for the k-th radio button toggle.
%                       --> If opts is a column vector only, prompt is used
%                           to define the radio button string names
%                       --> If opts has 2 columns, each element of 
%                           opts(:,2) is a string or char array that
%                           defines the name of a different radio button.
%
%  forceSelection :     (Optional) Default: true
%                       --> If specified as false, the default values in
%                           the popupmenu and listbox are used even if the
%                           user immediately exits or clicks submit without
%                           making a click on the interface.
%   --------
%    OUTPUT
%   --------
%    string_out :       Char array; corresponds to the user-selected option
%
%    group_out  :       Char array corresponding to radio-toggled group
%
%    index_out  :       Integer; corresponds to index of selected string

%% Handle inputs
if nargin < 4
   forceSelection = true;
end

if size(opts,2) == 1
   opts(:,2) = prompt;
end

if ~iscell(title_str)
   title_str = repmat({title_str},2,1);
elseif (numel(title_str)<2)
   title_str = [title_str; title_str];
end

if ~iscell(prompt)
   prompt = repmat({prompt},size(opts,1),1);
elseif (numel(prompt) < 2)
   prompt = repmat(prompt,size(opts,1),1);
end

% Make uiHandle class object to store information
if forceSelection
   h = nigeLab.utils.uiHandle('group','none','str','none','ind',nan);
else
   h = nigeLab.utils.uiHandle('group',opts{1,2},...
                              'str',opts{1,1}{1},...
                              'ind',[1, 1]);
end

%% CREATE DIALOG BOX
        
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
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
        
prompt_text = uicontrol('Style','text',...
           'Units','Normalized', ...
           'Position',[0.2 0.775 0.6 0.20],...
           'FontSize', 16, ...
           'BackgroundColor',nigeLab.defaults.nigelColors('surface'),...
           'ForegroundColor',nigeLab.defaults.nigelColors('primary'),...
           'String',prompt{1},...
           'UserData',prompt);
p.nestObj(prompt_text);

bg = uibuttongroup('Units','Normalized',...
   'Position',[0.05 0.05 0.6 0.30],...
   'FontSize',16,...
   'FontName','Arial',...
   'Title',title_str{2},...
   'BackgroundColor',nigeLab.defaults.nigelColors('surface'),...
   'ForegroundColor',nigeLab.defaults.nigelColors('primary'),...
   'UserData',ones(size(opts,1),1));
p.nestObj(bg);

nTotal = size(opts,1);
nCol = floor(sqrt(nTotal));
nRow = ceil(nTotal/nCol);

[y,H] = nigeLab.utils.uiGetVerticalSpacing(nRow,...
   'TOP',0.025,'BOT',0.025); % Offsets
[x,W] = nigeLab.utils.uiGetHorizontalSpacing(nCol,...
   'LEFT',0.025,'RIGHT',0.025); % Offsets

y = fliplr(y); % Start with first index at top
for i = 1:size(opts,1)
   rowIdx = rem(i-1,nRow)+1;
   colIdx = floor((i-1)/nRow)+1;
   fprintf(1,'Row: %g\t\tCol: %g\n',rowIdx,colIdx); % debug
   uicontrol(bg,...
      'Style','radiobutton',...
      'FontSize',16,...
      'FontName','Arial',...
      'String',opts{i,2},...
      'UserData',i,...
      'Units','Normalized',...
      'Position',[x(colIdx) y(rowIdx) W H],...
      'BackgroundColor',nigeLab.defaults.nigelColors('surface'),...
      'ForegroundColor',nigeLab.defaults.nigelColors('onsurface'));
      
end

str_box = uicontrol('Style','popupmenu',...
           'Units', 'Normalized', ...
           'Position',[0.05 0.4 0.9 0.30],...
           'FontSize', 16, ...
           'FontName','Arial',...
           'UserData',opts,...
           'String',opts{1,1});
        
p.nestObj(str_box);


submit_btn = uicontrol('Units', 'Normalized', ...
          'Position',[0.7 0.05 0.2 0.275],...
          'FontSize', 16, ...
          'String','SUBMIT',...
          'BackgroundColor',nigeLab.defaults.nigelColors('secondary'),...
          'ForegroundColor',nigeLab.defaults.nigelColors('onsecondary'));
p.nestObj(submit_btn);
       
%% Assign callbacks
submit_btn.Callback = @submit_selection;
str_box.Callback = {@assign_str,h,bg,prompt_text};
bg.SelectionChangedFcn = {@assign_group,h,str_box,prompt_text};

%% DEFINE DIALOG FUNCITONS
   function assign_group(src,~,h,str_box,pt)
      % ASSIGN_GROUP  Callback for when new radiobutton is clicked
      %
      %  bg.SelectionChangedFcn = {@assign_group,h,str_box,pt}; 
      %     
      %     h is nigeLab.libs.uiHandle class object that holds all the data
      %     bg is handle to uibuttongroup that contains the radio buttons
      %     str_box is handle to the popupmenu list box
      %     pt is handle to the prompt textbox uicontrol
      
      iGroup = src.SelectedObject.UserData;
      set(str_box,...
         'Value',src.UserData(iGroup),...
         'String',str_box.UserData{iGroup,1});
      
      iList = str_box.Value;
      iGroup = src.SelectedObject.UserData;
      set(pt,'String',pt.UserData{iGroup});
      
      set(h,...
         'str',str_box.String{str_box.Value},...
         'ind',[iGroup,iList],...
         'group',src.SelectedObject.String);
   end

   function assign_str(src,~,h,bg,pt)
      % ASSIGN_STR  Callback for when popupmenu is clicked
      %
      %  str_box.Callback = {@assign_str,h,bg,pt}; 
      %     
      %     h is nigeLab.libs.uiHandle class object that holds all the data
      %     bg is handle to uibuttongroup that contains the radio buttons
      %     str_box is handle to the popupmenu list box
      %     pt is handle to the prompt textbox uicontrol
      
      iList = src.Value;
      iGroup = bg.SelectedObject.UserData;
      pt.String = pt.UserData{iGroup};
      bg.UserData(iGroup) = iList; % Update "memory" for this group

      set(h,...
         'str',src.String{src.Value},...
         'ind',[iGroup,iList],...
         'group',bg.SelectedObject.String);

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
[string_out,group_out,index_out] = get(h,'str','group','ind');
delete(h);
clear('h');

end