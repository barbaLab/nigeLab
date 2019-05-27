function clearSpace(tankObj,ask)
%% CLEARSPACE   Delete the raw data folder to free some storage space
%
%  tank = nigeLab.Tank;
%  flag = clearSpace(tank);
%  flag = clearSpace(tank,ask);
%
%  --------
%   INPUTS
%  --------
%    tankObj   :     orgExp TANK class.
%
%    ask       :     True or false. CAUTION: setting this to false and
%                       running the CLEARSPACE method will automatically
%                       delete the rawData folder and its contents, without
%                       prompting to continue.
%
%  --------
%   OUTPUT
%  --------
%    flag      :     Boolean flag to report whether data was deleted.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% ASK TO CONFIRM FILE DELETION
A=tankObj.Animals;
if nargin<2
    ask=true;
end

String = {'Raw Data', sprintf('Filtered Data\n(Not rereferenced)')};
if ask
%% GUI
   
   %%% create figure
   F = figure('MenuBar','none','Units','normalized','Position',[.4 .4 .2 .3],...
      'Name','Deleting Files');
   F.Units = 'centimeters';
   F.Position(3:4)=[10 7];
   
   %%% Display title and text
   Text = sprintf(['Free up space']);
   T = uicontrol(F,'style','text','Units','normalized','Position',[.31 .82 .69 .15]...
      ,'String',Text,'HorizontalAlignment','left');
   T.FontName = 'Droid Sans';
   T.FontSize = 15;
   T.FontWeight = 'bold';
   
   Text = sprintf(['Here you can free up some space by deleting unneeded files.' ...
      '\nThis procedure is irreversible.']);
   T = uicontrol(F,'style','text','Units','normalized','Position',[.31 .67 .69 .2]...
      ,'String',Text,'HorizontalAlignment','left');
   T.FontName = 'Droid Sans';
   T.FontSize = 11;
   
   %%% Nerdly draw a disk icon
   ax = axes(F,'Units','normalized','Position',[0 .62 .3 .4]);
   plotdisk(ax);
   ax.XAxis.Visible=false;ax.YAxis.Visible=false;
   ax.Color = 'none';
   pbaspect(ax,[1 1 1]);
   
   %%% CheckBoxes!
   for ii = 1:numel(String)
      T.Units='centimeters';
      h = T.Position(2)-0.4 - .5*ii;
      cbk(ii) = uicontrol(F,'style','checkbox','Units','centimeters',...
         'Position',[T.Position(1) h 4 .5],...
         'String',String{ii});
         
   end
   
   Bu = uicontrol(F,'Style','pushbutton','Units','normalized',...
      'Position',[.75 .1 .15 .05],...
      'String','Delete!','Callback',{@DeleteStuff,cbk,ask,A,tankObj});
else
   DeleteStuff([],[],Choice,ask,B,tankObj);
end


end
function DeleteStuff(~,~,usrchoice,ask,A,tankObj)

if ask
   opts.Interpreter = 'tex';
   opts.Default = 'Cancel';
   promptMessage = sprintf(['Do you want to delete the selected ' ...
      'files?\nThis procedure is \\bf irreversible.'...
      '\n\n \\it With great power comes great responsibility.']);
   button = questdlg(promptMessage, 'Are you sure?', ...
      'Cancel', 'Continue',opts);
   if strcmpi(button, {'','Cancel'})
      fprintf(1,'-> No data deleted.\n');
      return;
   end
end

%% CONTINUE WITH FILE REMOVAL
%% PROCEED WITH REMOVING FILES
for ii=1:numel(A)
    ask = false;
    A(ii).clearSpace(ask,usrchoice);
end
tankObj.save;
fprintf(1,'Finished clearing space for: %s \n.',tankObj.Name);

end

function plotdisk(ax)
xlim(ax,[0 1]);ylim(ax,[0 1]);
x=0.5;y=0.5;r=.4;
th = 0:pi/50:2*pi;
xunit = r * cos(th) + x;
yunit = r * sin(th) + y;
h1 = plot(ax,xunit, yunit,'Color',[0 0 0],'LineWidth',3.7);
hold(ax,'on');

x=0.5;y=0.5;r=.1;
th = 0:pi/50:2*pi;
xunit = r * cos(th) + x;
yunit = r * sin(th) + y;
h2 = plot(ax,xunit, yunit,'Color',[0 0 0],'LineWidth',3.5);

x=0.5;y=0.5;r=.32;
th = pi/8:pi/50:pi/2;
xunit = r * cos(th) + x;
yunit = r * sin(th) + y;
h3 = plot(ax,xunit, yunit,'Color',[102 187 106]./255,'LineWidth',4);
end
