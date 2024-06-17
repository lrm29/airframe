classdef (ConstructOnLoad) MonitorEventData < event.EventData
    properties
        Name
        Data
        EventSource
        EventTime
        Message
    end

    methods
        function dataObj = MonitorEventData(options)
            arguments
                options.Name
                options.Data
                options.Source
                options.Message
            end

            dataObj.Name         = options.Name;
            dataObj.Data         = options.Data;
            dataObj.EventSource  = options.Source;
            dataObj.EventTime    = string(datetime('now'));
            dataObj.Message      = options.Message;
        end
    end
end