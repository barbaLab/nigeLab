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
      SavedState = false; % Description
      Default = 'P:\';
   end
   
   
   methods (Access = private)
      
      % Button pushed function: SaveButton
      function SaveNotes(app, ~)
         fid = fopen(app.Notes.File,'w');
         for ii = 1:size(app.NotesTextArea.Value,1)
            fprintf(fid,'%s\n',app.NotesTextArea.Value{ii});
         end
         fclose(fid);
         app.SavedState = true;
         if ~isempty(app.Parent)
            app.Parent.parseNotes(app.NotesTextArea.Value);
         end
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
         if ~app.SavedState
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
         
         % Create UIFigure
         app.UIFigure = uifigure;
         app.UIFigure.Position = [700 600 640 480];
         app.UIFigure.Name = 'UI Figure';
         app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @CheckSavedState, true);
         
         % Create NotesTextAreaLabel
         app.NotesTextAreaLabel = uilabel(app.UIFigure);
         app.NotesTextAreaLabel.VerticalAlignment = 'bottom';
         app.NotesTextAreaLabel.FontName = 'Arial';
         app.NotesTextAreaLabel.FontSize = 16;
         app.NotesTextAreaLabel.FontWeight = 'bold';
         app.NotesTextAreaLabel.Position = [20 446 477 20];
         
         [~,name,~] = fileparts(app.Notes.File);
         name = strrep(name,'_',' ');
         app.NotesTextAreaLabel.Text = sprintf('Notes: %s',name);
         
         
         % Create NotesTextArea
         app.NotesTextArea = uitextarea(app.UIFigure);
         app.NotesTextArea.Position = [20 34 477 403];
         if app.loadNotes
            app.NotesTextArea.Value = app.Notes.String;
         end
         
         % Create SaveButton
         app.SaveButton = uibutton(app.UIFigure, 'push');
         app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveNotes, true);
         app.SaveButton.FontName = 'Arial';
         app.SaveButton.FontSize = 16;
         app.SaveButton.Position = [519 84 100 29];
         app.SaveButton.Text = 'Save';
         
         % Create ExitButton
         app.ExitButton = uibutton(app.UIFigure, 'push');
         app.ExitButton.ButtonPushedFcn = createCallbackFcn(app, @ExitNotes, true);
         app.ExitButton.FontName = 'Arial';
         app.ExitButton.FontSize = 16;
         app.ExitButton.Position = [519 34 100 28];
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
               disp('Notes file not found.');
               return;
            end
         else
            disp('No notes file specified.');
            return;
         end  
         flag = true;
      end
   end
end