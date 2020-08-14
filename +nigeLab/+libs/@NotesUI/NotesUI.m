classdef NotesUI < matlab.apps.AppBase
   
   % Properties that correspond to app components
   properties (Access = public)
      UIFigure            matlab.ui.Figure
      NotesTextAreaLabel  matlab.ui.control.Label
      NotesTextArea       matlab.ui.control.TextArea
      SaveButton          matlab.ui.control.Button
      ExitButton          matlab.ui.control.Button
      Parent
      Notes
   end
   
   properties (Access = private)
      Default = 'P:\';    % Default location for notes creation
   end
   
   methods (Access = private)
      
      % Button pushed function: SaveButton
      function SaveNotes(app, ~)
         fid = fopen(app.Notes.File,'w');
         for ii = 1:size(app.NotesTextArea.Value,1)
            fprintf(fid,'%s\n',app.NotesTextArea.Value{ii});
         end
         fclose(fid);
         app.UIFigure.UserData = true;
         if ~isempty(app.Parent)
            app.Parent.parseNotes(app.NotesTextArea.Value);
         end
         %%%%%% I understand the goal of this dialog, i agree on its
         %%%%%% usefulness but it's freaking annoying
         % ^ then remove 'Notes' from Fields in defaults.Block -- MM
         selection = questdlg('Save successful. Finished taking notes?',...
            'Close Request',...
            'Exit','Cancel','Exit');
         if strcmp(selection,'Exit')
            ExitNotes(app);
         end
      end
      
      % Button pushed function: ExitButton
      function ExitNotes(app, ~)
         close(app.UIFigure);
         clear app
      end
      
      % Close request function: UIFigure
      function CheckSavedState(app, ~)
         if isempty(app.UIFigure)
            delete(app);
         end
         if ~isvalid(app.UIFigure)
            delete(app);
         end
         if ~app.UIFigure.UserData
            selection = questdlg('Current note changes unsaved. Save before exit?',...
               'Close Request Function',...
               'Save','Cancel','Exit','Save');
            if strcmp(selection,'Save')
               SaveNotes(app,nan);
               delete(app);
            elseif strcmp(selection,'Cancel')
               return;
            else
               delete(app);
            end
         else
            delete(app)
         end
         
      end
   end
   
   % App initialization and construction
   methods (Access = private)
      
      % Create UIFigure and components
      function createComponents(app)
         
         % Create normalized coordinates, thank you mathworks
         screenSize = get(groot,'ScreenSize');
         screenWidth = screenSize(3);
         screenHeight = screenSize(4);
         left = screenWidth*.2;
         bottom = screenHeight*.2;
         width = screenWidth*.2;
         height = screenHeight*.3;
         
         % Create UIFigure         
         app.UIFigure = uifigure;
         app.UIFigure.Position = [left bottom width height];
         app.UIFigure.Name = 'UI Figure';
         app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @CheckSavedState, true);
         
         % Create normalized coordinates... again, thank you mathworks
         FigSize = get(app.UIFigure,'Position');
         FigWidth = FigSize(3);
         FigHeight = FigSize(4);
         left = FigWidth;
         bottom = FigHeight;
         width = FigWidth;
         height = FigHeight;
         
         % Create NotesTextAreaLabel
         app.NotesTextAreaLabel = uilabel(app.UIFigure);
         app.NotesTextAreaLabel.VerticalAlignment = 'bottom';
         app.NotesTextAreaLabel.FontName = 'Arial';
         app.NotesTextAreaLabel.FontSize = 16;
         app.NotesTextAreaLabel.FontWeight = 'bold';
         app.NotesTextAreaLabel.Position = [left*.02 bottom*.92 width*.5 height*.1];
         
         [~,name,~] = fileparts(app.Notes.File);
         name = strsplit(name,'_');
         if numel(name) > 5
            name = strjoin(name(1:5),' ');
         else
            name = strjoin(name,' ');
         end
         
         app.NotesTextAreaLabel.Text = sprintf('Notes: %s',name);
         
         
         % Create NotesTextArea
         app.NotesTextArea = uitextarea(app.UIFigure);
         app.NotesTextArea.Position = [left*.05 bottom*.25 width*.9 height*.65];
         if app.loadNotes
            app.NotesTextArea.Value = app.Notes.String;
         else
            [~,f,~] = fileparts(app.Notes.File);
            fprintf(1,'\b Blank note (<strong>%s</strong>) created.\n',f);
         end
         
         % Create SaveButton
         app.SaveButton = uibutton(app.UIFigure, 'push');
         app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveNotes, true);
         app.SaveButton.FontName = 'Arial';
         app.SaveButton.FontSize = 16;
         app.SaveButton.Position = [left*.05 bottom*.1 width*.2 height*.1];
         app.SaveButton.Text = 'Save';
         
         % Create ExitButton
         app.ExitButton = uibutton(app.UIFigure, 'push');
         app.ExitButton.ButtonPushedFcn = createCallbackFcn(app, @ExitNotes, true);
         app.ExitButton.FontName = 'Arial';
         app.ExitButton.FontSize = 16;
         app.ExitButton.Position = [left*.75 bottom*.1 width*.2 height*.1];
         app.ExitButton.Text = 'Exit';
      end
   end
   
   methods (Access = public)
      
      % Construct app
      function app = NotesUI(fname,parent)
         if nargin==2
            app.Parent = parent;
         end
         
         
         if nargin < 1
            [f,p] = uiputfile('.txt','Set NOTES location',app.Default);
            if f == 0
               error('No file specified. Notes creation aborted.');
            end
            fname = fullfile(p,f);
         end
         app.Notes.File = fname;
         
         % Create and configure components
         createComponents(app)
         
         % Register the app with App Designer
         registerApp(app, app.UIFigure)
         app.UIFigure.UserData = false;
         
         if nargout == 0
            clear app
         end
      end
      
      % Code that executes before app deletion
      function delete(app)
         
         % Delete UIFigure when app is deleted
         delete(app.UIFigure)
      end
      
      function flag = loadNotes(app)
         flag = false;
         if isfield(app.Notes,'File')
            if exist(app.Notes.File,'file')~=0
               fid = fopen(app.Notes.File,'r');
               app.Notes.String = textscan(fid,'%s','delimiter','\n');  
               if ~isempty(app.Notes.String)
                  app.Notes.String = app.Notes.String{1}; 
               end
               fclose(fid);
            else
               fprintf(1,'\n\tNotes file not found.\n');
               p = fileparts(app.Notes.File);
               fname = fullfile(p,'.nigelBlock');
               if exist(fname,'file')~=0
                  fid = fopen(fname,'r');
                  app.Notes.String = textscan(fid,'%s','delimiter','\n');  
                  if ~isempty(app.Notes.String)
                     app.Notes.String = app.Notes.String{1}; 
                  end
                  fclose(fid);
                  fprintf(1,...
                     '\b Using <strong>.nigelBlock</strong> contents instead.\n');
                  flag = true;
               end
               return;
            end
         else
            fprintf(1,'\n\tNo notes file specified.\n');
            return;
         end  
         flag = true;
      end
   end
end