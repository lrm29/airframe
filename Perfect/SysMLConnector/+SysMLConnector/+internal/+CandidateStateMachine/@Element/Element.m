classdef Element < SysMLConnector.internal.CandidateElement
    %ELEMENT basic element of a state machine
    
    properties (SetAccess=protected)
        Parent
    end

    properties (Abstract,SetAccess=protected)
        StateflowObj
    end
    
    methods
        function elementObj = Element(externalElementID,parent)
            %ELEMENT Construct an instance of this class
            arguments
                externalElementID {mustBeText}
                parent 
            end
            elementObj@SysMLConnector.internal.CandidateElement( ...
                externalElementID);
            elementObj.Parent = parent;
        end
    end

    methods (Abstract)
        build(this);
    end
end

