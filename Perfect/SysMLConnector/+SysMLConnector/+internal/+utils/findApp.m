function app = findApp
    % findApp - find the SysML Connector app. If it is not running, this
    % will return empty. This utility assumed the app only has one running
    % instance.

    app = SysMLConnector.internal.app.Launcher.empty;
    
    allFigures = findall(groot,'Type','figure');

    if isempty(allFigures)
        return;
    end

    for figIdx = 1:numel(allFigures)
        thisFigure = allFigures(figIdx);
        if isprop(thisFigure, 'RunningAppInstance') && ~isempty(thisFigure.RunningAppInstance)
            if startsWith(class(thisFigure.RunningAppInstance), 'SysMLConnector.internal.app')
                app = thisFigure.RunningAppInstance;
                return;
            end
        end
    end
end