classdef Element < SysMLConnector.internal.CandidateElement & ...
        SysMLConnector.internal.CandidateStateMachine.Stateflow
    %ELEMENT basic element of a state machine
    
    properties (SetAccess=protected)
        Parent
        Built = false
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

        storeID(this);
    end

    methods (Abstract)
        build(this);
    end
end

