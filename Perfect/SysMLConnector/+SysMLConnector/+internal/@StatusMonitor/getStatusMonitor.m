function statusMonitor = getStatusMonitor
    persistent monitorCache

    % Check to see if the status monitor is cached already.
    if isempty(monitorCache) || ~isvalid(monitorCache)
        monitorCache = SysMLConnector.internal.StatusMonitor;
    end

    statusMonitor = monitorCache;
end