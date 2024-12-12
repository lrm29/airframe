classdef StateMachine < SysMLConnector.internal.CandidateElement & ...
        SysMLConnector.internal.CandidateStateMachine.RegionContainer &...
        SysMLConnector.internal.utils.Printable & ...
        SysMLConnector.internal.CandidateStateMachine.Stateflow & ...
        SysMLConnector.internal.OwnedBehavior
    %STATEMACHINE represents a state machine imported from SysML

    properties (SetAccess=protected)
        OwningArchitectureExtID string
    end

    methods
        function stateMachineObj = StateMachine(element, ownerExtElementID,...
                owningArchitectureExtID)
            %STATEMACHINE Construct an instance of this class
            arguments
                element umlmm.StateMachine
                ownerExtElementID {mustBeText}
                owningArchitectureExtID string = string.empty
            end
            stateMachineObj@SysMLConnector.internal.CandidateElement(...
                SysMLConnector.internal.utils.getExtID(element));
            stateMachineObj.Name = element.name;
            stateMachineObj.OwnerExtElementID = ownerExtElementID;
            % hold for later
            stateMachineObj.OwningArchitectureExtID = owningArchitectureExtID;
            %% enable requirement linking
            stateMachineObj.ValidRequirementLinkTarget = true;
            %% check for comments
            stateMachineObj.initializeComments(element);
            %% now to parse the regions
            stateMachineObj.Regions = SysMLConnector.internal.CandidateStateMachine.Region.empty(element.region.size,0);
            for i = 1:element.region.size
                stateMachineObj.Regions(i) = ...
                    SysMLConnector.internal.CandidateStateMachine.Region(...
                    element.region.at(i),stateMachineObj);
            end
        end

        linkPackage(this);
        prelimBuild(this,builder);
        finishBuild(this,builder);
        modelHandle = build(this,name);
        linkTarget = getLinkTarget(this);
    end
end
