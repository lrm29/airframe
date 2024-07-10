function addOutgoingTransition(this,transition)
%ADDOUTGOINGTRANSITION adds the outgoing transition to the node
arguments
    this SysMLConnector.internal.CandidateStateMachine.Node
    transition SysMLConnector.internal.CandidateStateMachine.Transition
end
this.OutgoingTransitions = [this.OutgoingTransitions,transition];
end

