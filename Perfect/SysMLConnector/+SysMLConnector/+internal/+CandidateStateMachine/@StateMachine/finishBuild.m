function finishBuild(this,builder)
%FINISHBUILD end of build
arguments
    this SysMLConnector.internal.CandidateStateMachine.StateMachine
    builder SysMLConnector.internal.Builder
end
if ~isempty(this.BehaviorComponent)
    % set the external ID
    if isempty(this.BehaviorComponent.ExternalUID)
        this.BehaviorComponent.ExternalUID = this.ExtElementID;
    end
    % convert the component to a Stateflow behavior
    this.BehaviorComponent.createStateflowChartBehavior();
    this.BuiltElement = find(sfroot,"-isa","Stateflow.Chart", ...
        Path=this.BehaviorComponent.getQualifiedName());
    for port = this.BehaviorComponent.Ports
        if isempty(port.ExternalUID)
            % check the architecture port
            if ~isempty(port.ArchitecturePort.ExternalUID)
                candidate = SysMLConnector.internal.CandidateElement.idMap(...
                    "lookup",port.ArchitecturePort.ExternalUID);
                updateCandidate(candidate,port);
            end
        else
            % update candidate name
            candidate = SysMLConnector.internal.CandidateElement.idMap(...
                "lookup",port.ExternalUID);
            updateCandidate(candidate,port);
        end
    end
end
builder.createStateMachine(this);
end

function updateCandidate(candidate,port)
% check that the candidate is the right one
if ~isempty(candidate)
    candidate = candidate( ...
        arrayfun(@(c) c.BuiltElement == port.ArchitecturePort,candidate));
    candidate.BuildName = char(port.Name);
end
end