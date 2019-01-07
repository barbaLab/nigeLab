function bg = uiAxesSelectionRadio(parent,Opts,selectionData,varargin)
%% UIAXESSELECTIONRADIO Create selection radio buttons to label axes
%
%  bg = UIAXESSELECTIONRADIO(parent,nOpts,selectionData,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%   parent     :     Handle to container object (uipanel) parent.
%
%   Opts       :     Cell array of option names. Grid format of cell array
%                    is copied for radio button layout.
%
%  selectionData :   Struct with two fields:
%                    -> 'cur' // Currently selected field in buttongroup
%                    -> 'idx' // Assigned "type" index for all axes
%
%  varargin    :     (Optional) 'NAME', value input argument pairs
%
%  --------
%   OUTPUT
%  --------
%    bg        :     Buttongroup object parent for the created radio
%                    buttons.
%
% By: Max Murphy  v1.0  03/22/2018  Original version (R2017b)

%% DEFAULTS
p = struct;
p.X_OFFSET = 0.100;
p.Y_OFFSET = 0.025;
p.FONTNAME = 'Arial';
p.FONTSIZE = 12;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   p.(upper(varargin{iV})) = varargin{iV+1};
end

%% CREATE PARENT FOR BUTTONS
bg = uibuttongroup(parent,...
                  'Visible','off',...
                  'Units','Normalized',...
                  'Position',[0 0 1 1],...
                  'SelectionChangedFcn',@(bg,evt) bselection(bg,evt),...
                  'UserData',selectionData);

%% GET LAYOUT DATA
[d1,d2] = size(Opts);
widthBtn  = (1 - p.X_OFFSET*(d2 + 1))/d2;
heightBtn = (1 - p.Y_OFFSET*(d1 + 1))/d1;

widthPos = widthBtn + p.X_OFFSET;
heightPos = heightBtn + p.Y_OFFSET;

%% LOOP THROUGH AND PLACE BUTTONS
ii = 1;

bg.UserData.b = cell(numel(Opts),1);
for i1 = 1:d1
   for i2 = 1:d2
      xpos = (i2-1)*widthPos + p.X_OFFSET;
      ypos = 1 - i1*heightPos;
      pos = [xpos ypos widthBtn heightBtn];
      if ii == 1
         bg.UserData.b{ii} = uicontrol(bg,'Style',...
            'radiobutton',...
            'FontName',p.FONTNAME,...
            'FontSize',p.FONTSIZE,...
            'String',Opts{i1,i2},...
            'Units','Normalized',...
            'Position',pos,...
            'HandleVisibility','off',...
            'Value',1,...
            'UserData',ii);
      else
         bg.UserData.b{ii} = uicontrol(bg,'Style',...
            'radiobutton',...
            'FontName',p.FONTNAME,...
            'FontSize',p.FONTSIZE,...
            'String',Opts{i1,i2},...
            'Units','Normalized',...
            'Position',pos,...
            'HandleVisibility','off',...
            'Value',0,...
            'UserData',ii);
      end
      ii = ii + 1;
   end
end
              
% Make the uibuttongroup visible after creating child objects. 
bg.Visible = 'on';

    function bselection(bg,evt)
      bg.UserData.cur = evt.NewValue.UserData;
    end
end