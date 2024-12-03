function prelimBuild(this,builder)
%PRELIMBUILD first step in build
arguments
    this SysMLConnector.internal.CandidateStateMachine.StateMachine
    builder SysMLConnector.internal.Builder
end
if ~isempty(this.OwningArchitectureExtID)
    % this state machine has an owning architecture
    owner = SysMLConnector.internal.CandidateElement.idMap("lookup",this.OwningArchitectureExtID);
    if owner.IsInlined 
        if isempty(owner.ChildComponents)
            % can directly convert component implementation of architecture to
            % a stateflow behavior
            component = owner.ReferencingComps.BuiltElement;
            component.createStateflowChartBehavior();
            this.BuiltElement = find(sfroot,"-isa","Stateflow.Chart", ...
                Path=owner.ReferencingComps.BuiltElement.getQualifiedName());
            for port = component.Ports
                if isempty(port.ExternalUID)
                    % check the architecture port
                    if ~isempty(port.ArchitecturePort.ExternalUID)
                        candidate = SysMLConnector.internal.CandidateElement.idMap(...
                            "lookup",port.ArchitecturePort.ExternalUID);
                        candidate.BuildName = char(port.Name);
                    end
                else
                    % update candidate name
                    candidate = SysMLConnector.internal.CandidateElement.idMap(...
                            "lookup",port.ExternalUID);
                    candidate.BuildName = char(port.Name);
                end
            end
        else
            % add a variant?
            disp("test");
        end
    end
end
builder.createStateMachine(this);
end

