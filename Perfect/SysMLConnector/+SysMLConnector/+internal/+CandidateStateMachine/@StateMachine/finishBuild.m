function finishBuild(this,builder)
%FINISHBUILD end of build
arguments
    this SysMLConnector.internal.CandidateStateMachine.StateMachine
    builder SysMLConnector.internal.Builder
end
if ~isempty(this.OwningArchitectureExtID)
    %% identify component to start from
    % this state machine has an owning architecture
    owner = SysMLConnector.internal.CandidateElement.idMap("lookup",this.OwningArchitectureExtID);
    if owner.IsInlined
        % start building from the reference component
        component = owner.ReferencingComps.BuiltElement;
    else
        % this architecture is re-used. That means it has its own file and
        % potential composition.
        if isempty(owner.ChildComponents)
            % If it is empty need to add a component for the behavior
            component = owner.BuiltElement.addComponent(this.Name);
            % copy and connect ports
            copyPortsToArchitecture(owner.BuiltElement.Ports, ...
                component.Architecture);
            % connect to the architectures ports
            connect(owner.BuiltElement,component,[]);
            connect(owner.BuiltElement,[],component);
        else
            % if not need to put everything in a component then add a variant
            % choice for the state machine behavior
            % combine all existing components
            Simulink.BlockDiagram.createSubsystem( ...
                [owner.BuiltElement.Components.SimulinkHandle]);
            systemcomposer.internal.arch.internal.processBatchedPluginEvents( ...
                owner.BuiltElement.SimulinkModelHandle);
            component = owner.BuiltElement.Components;
            component.Name = owner.BuiltElement.Name;
        end
        % make pretty
        Simulink.BlockDiagram.arrangeSystem( ...
            owner.BuiltElement.getQualifiedName(), ...
            FullLayout='true');
    end
    %% convert component
    if isempty(owner.ChildComponents)
        % can directly convert component implementation of architecture to
        % a Stateflow behavior
        component.createStateflowChartBehavior();
        this.BuiltElement = find(sfroot,"-isa","Stateflow.Chart", ...
            Path=component.getQualifiedName());
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
            % make pretty
            Simulink.BlockDiagram.arrangeSystem(...
                variant.Parent.getQualifiedName(),FullLayout='true');
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
            % fix the ref component 
            if owner.IsInlined
                owner.ReferencingComps.BuiltElement = variant;
            end
        end
        % add a variant choice
        smUniqueName = matlab.lang.makeUniqueStrings(this.Name, ...
            string({variant.OwnedArchitecture.Components.Name}));
        choice = variant.addChoice(smUniqueName, ...
            "OwnedBehavior");%+string(smUniqueName));
        % add ports to the new choice
        copyPortsToArchitecture(component.Ports,choice.Architecture);
        % make it pretty
        Simulink.BlockDiagram.arrangeSystem(variant.getQualifiedName(), ...
            FullLayout='true');
        % make it a Stateflow behavior
        choice.createStateflowChartBehavior();
        this.BuiltElement = find(sfroot,"-isa","Stateflow.Chart", ...
            Path=choice.getQualifiedName());        
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

function newPorts = copyPortsToArchitecture(ports,architecture)
% copies the ports to the provided architecture
arguments
    ports systemcomposer.arch.BasePort
    architecture systemcomposer.arch.Architecture
end
if isscalar(ports)
    switch ports.Direction
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
                "Port type %s is invalid",string(ports.Direction));
    end
    newPorts = architecture.addPort(ports.Name,type);
    newPorts.setInterface(ports.Interface);
else
    newPorts = arrayfun(@(p) copyPortsToArchitecture(p,architecture),ports);
end
end

