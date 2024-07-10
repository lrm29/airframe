function addIncomingTransition(this,transition)
%ADDINCOMINGTRANSITION adds the transition to the node
arguments
    this SysMLConnector.internal.CandidateStateMachine.Node
    transition SysMLConnector.internal.CandidateStateMachine.Transition
end
this.IncomingTransitions = [this.IncomingTransitions,transition];
end

