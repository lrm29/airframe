function build(this)
%BUILD builds the junctions
arguments
    this SysMLConnector.internal.CandidateStateMachine.Port
end
if this.Junction.Built && ~ this.Built
    this.BuiltElement = Stateflow.findMatchingPort(this.Junction.BuiltElement);
end
end