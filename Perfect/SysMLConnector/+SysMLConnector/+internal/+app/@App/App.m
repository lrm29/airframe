classdef App < handle
    properties (SetAccess=private)
        Launcher
        Importer
        Exporter
    end

    properties (Dependent)
        ActiveWindow
        Mode
        Position
    end

    properties (GetAccess=private)
        SkipDelete = false;
    end

    methods (Access=private)
        function app = App(options)
            arguments
                options.NoInit = false;
            end

            if ~options.NoInit
                initialize(app);
            end
        end

        function initialize(app, options)
            arguments
                app
                options.Launcher = SysMLConnector.internal.app.Launcher;
                options.Importer = SysMLConnector.internal.app.Importer;
                options.Exporter = SysMLConnector.internal.app.Exporter;
            end
            
            app.Launcher = options.Launcher;            
            app.Importer = options.Importer;
            app.Exporter = options.Exporter;

            app.Launcher.UIFigure.Visible = 'on';

            [isNotCompatible, errorID, errorMsg] = SysMLConnector.internal.utils.mustBeCompatibleVersionOrLater(ErrorLevel='none');

            if isNotCompatible
                uialert(app.Launcher.UIFigure, errorMsg, errorID, Icon='warning')
            end
        end
    end

    methods % Dependent
        function activeWindow = get.ActiveWindow(app)
            switch app.Mode
                case 'Launcher'
                    activeWindow = app.Launcher;
                case 'Importer'
                    activeWindow = app.Importer;
                case 'Exporter'
                    activeWindow = app.Exporter;
                otherwise
                    activeWindow = [];
            end
        end

        function mode = get.Mode(app)
            if strcmp(app.Launcher.UIFigure.Visible,     'on')
                mode = 'Launcher';
            elseif strcmp(app.Importer.UIFigure.Visible, 'on')
                mode = 'Importer';
            elseif strcmp(app.Exporter.UIFigure.Visible, 'on')
                mode = 'Exporter';
            end
        end

        function position = get.Position(app)
            position = app.ActiveWindow.UIFigure.Position;
        end

        function set.Mode(app, mode)
            arguments
                app
                mode (1,:) char {mustBeMember(mode, {'Launcher', 'Importer', 'Exporter'})}
            end

            oldAppWindow = app.ActiveWindow;

            switch mode
                case 'Launcher'
                    newAppWindow = app.Launcher;
                case 'Importer'
                    newAppWindow = app.Importer;
                case 'Exporter'
                    newAppWindow = app.Exporter;
            end 

            app.centerWindowOnReference(newAppWindow, oldAppWindow);
            app.hide(oldAppWindow);
            app.show(newAppWindow);           
        end

        function set.Position(app, position)
            app.ActiveWindow.UIFigure.Position = position;
        end
    end

    methods % Utilities
        function close(app)
            delete(app);
        end

        function delete(app)
            if ~app.SkipDelete
                delete(app.Launcher);
                delete(app.Importer);
                delete(app.Exporter);
            end
        end
    end

    methods (Static)
        app = getApp; % Singleton

        function centerWindowOnReference(window, reference)
            targetPosition = window.UIFigure.Position;
            referencePosition = reference.UIFigure.Position;

            referenceCenterX = referencePosition(1) + floor(referencePosition(3)/2);
            referenceCenterY = referencePosition(2) + floor(referencePosition(4)/2);
            position =  [referenceCenterX - floor(targetPosition(3)/2), ...
                         referenceCenterY - floor(targetPosition(4)/2), ...
                         targetPosition(3), ...
                         targetPosition(4)];

            window.UIFigure.Position = position;
        end

        function cleanEnvironment
            app = SysMLConnector.internal.app.App.getApp;

            appWindow = app.ActiveWindow;
            
            selection = uiconfirm(appWindow.UIFigure, 'Cleaning the environment may result in loss of any unsaved artifacts, including models, dictionaries, and workspace variables. Are you sure you want to clean the environment?', 'Confirm Clean Environment');

            if strcmp(selection, 'OK')
                % The app will need to be restarted so cache its
                % information
                app.SkipDelete = true;
                appPosition = app.Position;
                appMode     = app.Mode;

                d = uiprogressdlg(appWindow.UIFigure, Title='Please Wait', Message='Cleaning MATLAB Environment', Indeterminate='on');
                evalin('base', 'SysMLConnector.cleanEnvironment;');

                d.Message = 'Restarting SysML Connector...';
                % Pause so the user has time to see the alert.
                pause(0.5);
                SysMLConnector.internal.app.App.restart(Window=appWindow, Position=appPosition, Mode=appMode);

                close(d);
            end
        end

        function restart(options)
            % Restart the app but retain the existing window (needed for
            % when cleanEnvironment is called).
            arguments
                options.Mode
                options.Position
                options.Window
            end

            app = SysMLConnector.internal.app.App.getApp(NoInit=true);
            
            switch options.Mode
                case 'Launcher'
                    app.Launcher = options.Window;
                case 'Importer'
                    app.Importer = options.Window;
                case 'Exporter'
                    app.Exporter = options.Window;
            end 

            if isempty(app.Launcher)
                app.Launcher = SysMLConnector.internal.app.Launcher;
                app.hide(app.Launcher);
            end

            if isempty(app.Importer)
                app.Importer = SysMLConnector.internal.app.Importer;
                app.hide(app.Importer);
            end

            if isempty(app.Exporter)
                app.Exporter = SysMLConnector.internal.app.Exporter;
                app.hide(app.Exporter);
            end

            app.Position = options.Position;
        end

        function shutdown
            app = SysMLConnector.internal.app.App.getApp;

            delete(app);
        end

        function hide(window)
            window.UIFigure.Visible = 'off';
        end

        function show(window)
            window.UIFigure.Visible = 'on';
            SysMLConnector.internal.app.App.toFront;
        end

        function showLauncher
            app = SysMLConnector.internal.app.App.getApp;
            app.Mode = 'Launcher';
        end

        function showImporter
            app = SysMLConnector.internal.app.App.getApp;
            app.Mode = 'Importer';
        end

        function showExporter
            app = SysMLConnector.internal.app.App.getApp;
            app.Mode = 'Exporter';
        end

        function toFront
            app = SysMLConnector.internal.app.App.getApp;

            % Bring the app to the foreground (UI workaround).
            warnState = warning('off', 'MATLAB:callback:error'); % Nuisance message
            cleanup = onCleanup(@() warning(warnState));
            drawnow;
            figure(app.ActiveWindow.UIFigure);
        end
    end
end