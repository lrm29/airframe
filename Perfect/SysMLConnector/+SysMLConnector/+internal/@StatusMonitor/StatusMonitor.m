classdef StatusMonitor < handle
    properties
        EventLog
        EventIndex
        SourceTool
    end
    
    properties (SetAccess=private)
        Debug (1,1) logical = false
        CancelRequestCallback = []
        CancelRequestInhibited = false
    end

    % Outgoing Events
    events (NotifyAccess=private)
        MessageService
    end

    methods (Access = private)
        function monitorObj = StatusMonitor
            monitorObj.EventLog   = dictionary;
            monitorObj.EventIndex = 0;
        end

        function logEvent(statusMonitor, event)
            statusMonitor.EventIndex = statusMonitor.EventIndex + 1;
            statusMonitor.EventLog(statusMonitor.EventIndex) = event;
        end
    end

    methods (Static)
        statusMonitor = getStatusMonitor;

        function sourceTool = getSourceTool
            statusMonitor = SysMLConnector.internal.StatusMonitor.getStatusMonitor;
            sourceTool = statusMonitor.SourceTool;
        end

        function setSourceTool(sourceTool)
            arguments
                sourceTool (1,:) char
            end

            statusMonitor = SysMLConnector.internal.StatusMonitor.getStatusMonitor;
            statusMonitor.SourceTool = sourceTool;
        end

        function addCancelRequestCallback(callback)
            statusMonitor = SysMLConnector.internal.StatusMonitor.getStatusMonitor;
            statusMonitor.CancelRequestCallback = callback;
        end

        function inhibitCancelRequest
            statusMonitor = SysMLConnector.internal.StatusMonitor.getStatusMonitor;
            statusMonitor.CancelRequestInhibited = true;
        end

        function removeCancelRequestCallback
            statusMonitor = SysMLConnector.internal.StatusMonitor.getStatusMonitor;
            statusMonitor.CancelRequestCallback = [];
        end

        function uninhibitCancelRequest
            statusMonitor = SysMLConnector.internal.StatusMonitor.getStatusMonitor;
            statusMonitor.CancelRequestInhibited = false;
        end

        function enableDebug
            statusMonitor = SysMLConnector.internal.StatusMonitor.getStatusMonitor;
            statusMonitor.Debug = true;
        end

        function showLog
            statusMonitor = SysMLConnector.internal.StatusMonitor.getStatusMonitor;

            if statusMonitor.EventLog.numEntries > 0
                eventNumber = statusMonitor.EventLog.keys;
                eventArray  = statusMonitor.EventLog.values;
    
                eventTable = table(eventNumber, string({eventArray.EventName})', {eventArray.Data}', arrayfun(@(source) string(class(source{:})),{eventArray.Source}'), ...
                    VariableNames={'ID', 'Name', 'Data', 'Source'});
    
                disp(eventTable);
            else
                disp('The event log is empty.')
            end
        end

        function publishEvent(eventName, eventData, eventMessage, varargin)
            arguments
                eventName    = ''
                eventData    = ''
                eventMessage = ''
            end

            arguments (Repeating)
                varargin
            end

            % Escape backslashes.
            eventMessage = strrep(eventMessage, '\', '\\');

            eventMessage = sprintf(eventMessage, varargin{:});

            stack = dbstack(1, '-completenames');
            
            sourceFile = stack(1).file;
            sourceLine = num2str(stack(1).line);

            [sourceFilePath, sourceFileName] = fileparts(sourceFile);

            sourceFileWithoutExtension = fullfile(sourceFilePath, sourceFileName);

            eventSource = extractAfter(sourceFileWithoutExtension, [SysMLConnector.internal.toolboxRoot '\+']);
            eventSource = strrep(eventSource, '+', '');
            eventSource = strrep(eventSource, '\', '.');
            eventSource = [eventSource ':' sourceLine];

            statusMonitor = SysMLConnector.internal.StatusMonitor.getStatusMonitor;
            eventDataObject = SysMLConnector.internal.StatusMonitor.MonitorEventData(...
                                     Name=eventName, ...
                                     Data=eventData, ...
                                     Source=eventSource, ...
                                     Message=eventMessage);

            statusMonitor.logEvent(eventDataObject);            

            if statusMonitor.Debug
                fprintf('%s Event: %s::%s::%s\n', eventDataObject.EventTime, eventSource, eventName, eventMessage);
            end

            notify(statusMonitor, 'MessageService', eventDataObject);

            % Check for cancel event
            if ~statusMonitor.CancelRequestInhibited && ~isempty(statusMonitor.CancelRequestCallback) && statusMonitor.CancelRequestCallback()
                eventDataObject = SysMLConnector.internal.StatusMonitor.MonitorEventData(...
                         Name='CancelRequest', ...
                         Data='', ...
                         Source='', ...
                         Message='Cancel requested, aborting import.');

                notify(statusMonitor, 'MessageService', eventDataObject);

                error('SysMLConnector:import:CancelRequested', 'Cancel request received. Terminating import.');
            end
        end

        function listener = registerListener(callback)
            statusMonitor = SysMLConnector.internal.StatusMonitor.getStatusMonitor;
            listener = addlistener(statusMonitor, 'MessageService', callback);
        end

        function unregisterListener(listener)
            delete(listener);
        end
    end
end