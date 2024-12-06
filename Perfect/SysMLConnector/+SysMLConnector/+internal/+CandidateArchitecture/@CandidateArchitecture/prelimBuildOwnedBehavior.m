function prelimBuildOwnedBehavior(this,~)
%FINISHBUILDOWNEDBEHAVIOR Builds out owned behaviors managing any variants
%that need to be built
arguments
    this SysMLConnector.internal.CandidateArchitecture.CandidateArchitecture
    ~
end
if ~isempty(this.OwnedBehaviors)
    % need behaviors to build
    if this.IsInlined
        if isscalar(this.OwnedBehaviors) && isempty(this.ChildComponents)
            % if there is only one behavior and this architecture has no
            % child components this is simple
            this.OwnedBehaviors.setBehaviorComponent(this.ReferencingComps.BuiltElement);
        else
            % need a variant to hold behaviors and children
            component = this.ReferencingComps.BuiltElement;
            variant = component.makeVariant();
            % move the external ID to the variant component
            variant.ExternalUID = component.ExternalUID;
            component.ExternalUID = '';
            % fix the ref component
            this.ReferencingComps.BuiltElement = variant;
            % make pretty
            Simulink.BlockDiagram.arrangeSystem(...
                variant.Parent.getQualifiedName(),FullLayout='true');
            % now to add choices for the behaviors
            addChoices(this,variant);
        end
    else
        variantFlag = true;
        if isempty(this.ChildComponents)
            % with no child components new components need to be added for
            % behaviors
            if isscalar(this.OwnedBehaviors)
                % if only one name it after the behavior
                component = this.BuiltElement.addComponent(this.OwnedBehaviors.Name);
                % this is the only case without a variant
                variantFlag = false;
            else
                % for multiple behaviors give the new component a common name
                component = this.BuiltElement.addComponent("Owned Behaviors");
                variant = component.makeVariant();
                % in this case the original component needs to be destroyed
                warnings = warning;
                warning('off','Simulink:Variants:VSSLabelRemovedOrUpdated');
                cleanup = onCleanup(@() warning(warnings));
                component.destroy();
                component = variant;
            end
            connectToArchitecture(this.BuiltElement,component);
        else
            % need to collect the child components into a new component
            % before adding behaviors
            Simulink.BlockDiagram.createSubsystem( ...
                [this.BuiltElement.Components.SimulinkHandle]);
            systemcomposer.internal.arch.internal.processBatchedPluginEvents( ...
                this.BuiltElement.SimulinkModelHandle);
            component = this.BuiltElement.Components;
            component.Name = this.BuiltElement.Name;
            % need to make this a variant 
            component.makeVariant();
        end
        if variantFlag
            addChoices(this,component);
        else
            this.OwnedBehaviors.setBehaviorComponent(component);
        end
        % make it pretty
        Simulink.BlockDiagram.arrangeSystem( ...
            this.BuiltElement.getQualifiedName(),FullLayout='true');
    end
end
end

function connectToArchitecture(architecture,component)
arguments
    architecture systemcomposer.arch.Architecture
    component systemcomposer.arch.BaseComponent
end
% copy and connect ports
copyPortsToArchitecture(architecture.Ports, ...
    component.OwnedArchitecture);
% connect to the architectures ports
connect(architecture,component,[]);
connect(architecture,[],component);
end

function addChoices(this,variant)
% adds choices to the variant component and assigns them to behaviors
arguments 
    this SysMLConnector.internal.CandidateArchitecture.CandidateArchitecture
    variant systemcomposer.arch.VariantComponent
end
for i = 1:numel(this.OwnedBehaviors)
    % add a variant choice
    choice = variant.addChoice("OwnedBehavior"+num2str(i), ...
        "OwnedBehavior"+num2str(i));
    % add ports to the new choice
    copyPortsToArchitecture(variant.Ports,choice.Architecture);
    % add a component within the choice to wrap any behavior
    component = choice.OwnedArchitecture.addComponent( ...
        this.OwnedBehaviors(i).Name);
    connectToArchitecture(choice.OwnedArchitecture,component);
    % make it pretty
    Simulink.BlockDiagram.arrangeSystem(choice.getQualifiedName(), ...
        FullLayout='true');
    % let the behavior know where to build
    this.OwnedBehaviors(i).setBehaviorComponent(component);
end
% make it pretty
Simulink.BlockDiagram.arrangeSystem(variant.getQualifiedName(), ...
    FullLayout='true');
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