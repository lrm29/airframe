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
        component = owner.ReferencingComps.BuiltElement;
        if isempty(owner.ChildComponents)
            % can directly convert component implementation of architecture to
            % a stateflow behavior
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
            % add a variant
            variant = component.makeVariant();
            choice = variant.addChoice(this.Name);
            choice.createStateflowChartBehavior();
            this.BuiltElement = find(sfroot,"-isa","Stateflow.Chart", ...
                Path=choice.getQualifiedName());
            % move all the external IDs to the new component
            variant.ExternalUID = component.ExternalUID;
            component.ExternalUID = '';
            % architecture external ID is moved automatically
            component.Architecture.ExternalUID = '';
            for i = 1:numel(component.Architecture.Ports)
                variant.Architecture.Ports(i).ExternalUID = ...
                    component.Architecture.Ports(i).ExternalUID;
                component.Architecture.Ports(i).ExternalUID = '';
            end
        end
    end
end
builder.createStateMachine(this);
end

