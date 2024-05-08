function app
    %% SysML Connector App - This application can be used to import and export SysML models from System Composer.
    %
    % To launch the app, select "SysML Connector" from the MY APPS section of the
    % MATLAB Apps tray or type the command:
    %    SysMLConnector.app
    %
    % The <a href="matlab:SysMLConnector.internal.doc('GettingStarted_Scr.html');">Getting Started with the SysML Connector</a> page provides instructions
    % on how to use the SysML Connector Application. 
    %
    % See the <a href="matlab:SysMLConnector.internal.doc('UserGuide_Scr.html');">SysML Connector User Guide</a> for information about the SysML Connector.
    %
    app = SysMLConnector.internal.utils.findApp;

    if isempty(app)
        SysMLConnector.internal.app.Launcher;
    else
        SysMLConnector.internal.utils.toFront(app);
    end
end