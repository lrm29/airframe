function parseFinalState(this,element)
%PARSEFINALSTATE parse final state
arguments
    this SysMLConnector.internal.CandidateStateMachine.State
    element umlmm.FinalState %#ok<INUSA>
end
this.Name = "Final State";
end

