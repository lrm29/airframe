function app = getApp(options)
    arguments
        options.NoInit = false
    end

    persistent appCache

    % Check to see if the app is cached already.
    if isempty(appCache) || ~isvalid(appCache)
        appCache = SysMLConnector.internal.app.App(NoInit=options.NoInit);
    end

    % Check to make sure the app is healthy.
    if ~options.NoInit && ( isempty(appCache.Launcher)  ...
                         || isempty(appCache.Importer)  ...
                         || isempty(appCache.Importer)  ...
                         || ~isvalid(appCache.Launcher) ...
                         || ~isvalid(appCache.Importer) ...
                         || ~isvalid(appCache.Exporter))
        % The app is not healthy so delete it and do a clean launch.
        delete(appCache);

        appCache = SysMLConnector.internal.app.App(NoInit=options.NoInit);
    end

    app = appCache;
end