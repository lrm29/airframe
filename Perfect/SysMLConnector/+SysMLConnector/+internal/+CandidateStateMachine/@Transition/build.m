function build(this)
%BUILD builds this transition
arguments
    this SysMLConnector.internal.CandidateStateMachine.Transition
end
if ~isempty(this.Source) && ~isempty(this.Target)
    this.BuiltElement = Stateflow.Transition(this.Owner.BuiltElement);
    this.BuiltElement.Source = this.Source.BuiltElement;
    this.BuiltElement.Destination = this.Target.BuiltElement;
    this.BuiltElement.LabelString = this.LabelString;
    this.storeID();
else
    warning( ...
        "SysMLConnector:internal:CandidateStateMachine:Transition:build",...
        "Transition with ID %s was not valid and was not built.",...
        this.ExtElementID);
end

