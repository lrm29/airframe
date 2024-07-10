function build(this)
%BUILD builds this transition
arguments
    this SysMLConnector.internal.CandidateStateMachine.Transition
end
this.StateflowObj = Stateflow.Transition(this.Parent.StateflowObj);
this.StateflowObj.Source = this.Source.StateflowObj;
this.StateflowObj.Destination = this.Target.StateflowObj;
this.StateflowObj.LabelString = this.LabelString;
end

