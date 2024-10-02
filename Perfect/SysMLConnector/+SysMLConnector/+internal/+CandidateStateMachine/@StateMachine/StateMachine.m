classdef StateMachine < SysMLConnector.internal.CandidateElement & ...
        SysMLConnector.internal.CandidateStateMachine.RegionContainer &...
        SysMLConnector.internal.utils.Printable & ...
        SysMLConnector.internal.CandidateStateMachine.Stateflow
    %STATEMACHINE represents a state machine imported from SysML

    properties (SetAccess=protected)
        Name
        ParentPackageExtElementID
        ParentPackage
        BuildName
        StateflowObj
    end

    properties (Dependent,SetAccess=protected)
        Built
    end

    methods
        function stateMachineObj = StateMachine(element,parentPackageExtElementID)
            %STATEMACHINE Construct an instance of this class
            arguments
                element umlmm.StateMachine
                parentPackageExtElementID {mustBeText}
            end
            stateMachineObj@SysMLConnector.internal.CandidateElement(...
                SysMLConnector.internal.utils.getExtID(element));
            stateMachineObj.Name = element.name;
            stateMachineObj.ParentPackageExtElementID = parentPackageExtElementID;
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

        function Built = get.Built(this)
            arguments
                this SysMLConnector.internal.CandidateStateMachine.StateMachine
            end
            Built = ~isempty(this.StateflowObj);
        end
    end

    methods (Access={?SysMLConnector.internal.Builder})
        function setBuildName(this, buildName)
            this.BuildName = buildName;
        end
    end
end
