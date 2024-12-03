function prelimBuild(this,builder)
%PRELIMBUILD first step in build
arguments
    this SysMLConnector.internal.CandidateStateMachine.StateMachine
    builder SysMLConnector.internal.Builder
end
if ~isempty(this.OwningArchitectureExtID)
    % this state machine has an owning architecture
    owner = SysMLConnector.internal.CandidateElement.idMap("lookup",this.OwningArchitectureExtID);
    if owner.IsInlined && isempty(owner.ChildComponents)
        % can directly convert component implementation of architecture to
        % a stateflow behavior
        component = owner.ReferencingComps.BuiltElement;
        component.createStateflowChartBehavior();
        this.BuiltElement = find(sfroot,"-isa","Stateflow.Chart", ...
            Path=owner.ReferencingComps.BuiltElement.getQualifiedName());
    end
end
builder.createStateMachine(this);
end

