classdef Printable < handle
    %PRINTABLE for printable elements of a state machine
    
    properties (SetAccess=protected)
        ShallowProperties = string.empty()
        ExcludedProperties = "Parent"
        ShortProperties = string.empty();
    end

    properties (Abstract,SetAccess=protected)
        Built
    end

    methods
        print(this,printer);
        shallowPrint(this,printer);
        idString = getPrintID(this);
        shortPrint(this,printer);
        infoString = getInfoString(this);
    end

    methods (Access=protected)
        printableProperties = getPrintableProperties(this);
    end

    methods (Access=protected,Static)
        printables = getPrintables(item);
    end
end

