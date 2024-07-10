function build(this)
%BUILD builds the sate
arguments
    this SysMLConnector.internal.CandidateStateMachine.State
end
this.StateflowObj = Stateflow.State(this.Parent.StateflowObj);
this.StateflowObj.Name = this.Name;
end

