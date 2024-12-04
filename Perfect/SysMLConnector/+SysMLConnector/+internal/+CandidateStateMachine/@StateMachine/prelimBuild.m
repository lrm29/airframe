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
            % a Stateflow behavior
            component.createStateflowChartBehavior();
            this.BuiltElement = find(sfroot,"-isa","Stateflow.Chart", ...
                Path=owner.ReferencingComps.BuiltElement.getQualifiedName());
            for port = component.Ports
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
        else
            if isa(component,"systemcomposer.arch.VariantComponent")
                % component is a variant just need to add a choice to it
                variant = component;
            else
                % need to make the component a variant
                variant = component.makeVariant();
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
            % add a variant choice
            choice = variant.addChoice(...
                matlab.lang.makeUniqueStrings(this.Name, ...
                string({variant.OwnedArchitecture.Components.Name})));
            % add ports to the new choice
            for port = component.Ports
                switch port.Direction
                    case systemcomposer.arch.PortDirection.Input
                        type = "in";
                    case systemcomposer.arch.PortDirection.Output
                        type = "out";
                    case systemcomposer.arch.PortDirection.Client
                        type = "client";
                    case systemcomposer.arch.PortDirection.Physical
                        type = "physical";
                    case systemcomposer.arch.PortDirection.Server
                        type = "server";
                    otherwise
                        error("SysMLConnector:internal:CandidateStateMachine:StateMachine:prelimBuild:InvalidPortType",...
                            "Port type %s is invalid",string(port.Direction));
                end
                newPort = choice.Architecture.addPort(port.Name,type);
                newPort.setInterface(port.Interface);
            end
            % make it a Stateflow behavior
            choice.createStateflowChartBehavior();
            this.BuiltElement = find(sfroot,"-isa","Stateflow.Chart", ...
                Path=choice.getQualifiedName());
        end
    end
end
builder.createStateMachine(this);
end

function updateCandidate(candidate,port)
% check that the candidate is the right one
candidate = candidate( ...
    arrayfun(@(c) c.BuiltElement == port.ArchitecturePort,candidate));
candidate.BuildName = char(port.Name);
end