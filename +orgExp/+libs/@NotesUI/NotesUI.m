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
            app.Parent.UpdateNotes(app.NotesTextArea.Value);
            selection = questdlg('Save successful. Finished taking notes?',...
               'Close Request',...
               'Exit','Cancel','Exit');
            if strcmp(selection,'Exit')
               delete(app);
            end
        end

        % Button pushed function: ExitButton
        function ExitNotes(app, ~)
            close(app.UIFigure);
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
            app.NotesTextAreaLabel.Position = [20 446 50 20];
            app.NotesTextAreaLabel.Text = 'Notes';
            
            
            % Create NotesTextArea
            app.NotesTextArea = uitextarea(app.UIFigure);
            app.NotesTextArea.Position = [20 34 477 403];

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
        function app = NotesUI

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
        
        function addNotes(app,parent,Notes_In)
           app.Notes = Notes_In;
           app.Parent = parent;
           if ~isempty(Notes_In.String)
               app.NotesTextArea.Value = Notes_In.String{1};
           end
           
           
        end
    end
end