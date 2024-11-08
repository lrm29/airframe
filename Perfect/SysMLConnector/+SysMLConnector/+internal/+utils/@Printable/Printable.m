classdef Printable < handle
    %PRINTABLE for printable elements of a state machine
    
    properties (SetAccess=protected)
        ShallowProperties = string.empty()
        ExcludedProperties = "Owner"
        ShortProperties = string.empty();
    end

    methods
        print(this,printer);
        shallowPrint(this,printer);
        shortPrint(this,printer);
    end

    methods (Access=protected)
        printableProperties = getPrintableProperties(this);
        infoString = getInfoString(this);
        idString = getPrintID(this);
        shortString = getShortPrintString(this);
    end

    methods (Access=protected,Static)
        printables = getPrintables(item);
    end
end

