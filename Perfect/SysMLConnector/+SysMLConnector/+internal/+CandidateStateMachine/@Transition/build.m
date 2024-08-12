function build(this)
%BUILD builds this transition
arguments
    this SysMLConnector.internal.CandidateStateMachine.Transition
end
if ~isempty(this.Source) && ~isempty(this.Target)
    this.StateflowObj = Stateflow.Transition(this.Parent.StateflowObj);
    this.StateflowObj.Source = this.Source.StateflowObj;
    this.StateflowObj.Destination = this.Target.StateflowObj;
    this.StateflowObj.LabelString = this.LabelString;
    this.storeID();
else
    warning( ...
        "SysMLConnector:internal:CandidateStateMachine:Transition:build",...
        "Transition with ID %s was not valid and was not built.",...
        this.ExtElementID);
end

