classdef Element < SysMLConnector.internal.CandidateElement & ...
        SysMLConnector.internal.CandidateStateMachine.Stateflow & ...
        SysMLConnector.internal.utils.Printable 
    %ELEMENT basic element of a state machine
    
    methods
        function elementObj = Element(element,parent)
            %ELEMENT Construct an instance of this class
            arguments
                element
                parent 
            end
            elementObj@SysMLConnector.internal.CandidateElement( ...
                SysMLConnector.internal.utils.getExtID(element));
            elementObj.Owner = parent;
            %% enable requirement linking
            elementObj.ValidRequirementLinkTarget = true;
            %% check for comments
            elementObj.initializeComments(element);
        end

        storeID(this);
        linkTarget = getLinkTarget(this);
    end

    methods (Abstract)
        build(this);
    end
end

