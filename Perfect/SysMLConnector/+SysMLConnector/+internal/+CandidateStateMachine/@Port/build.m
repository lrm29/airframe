function build(this)
%BUILD builds the junctions
arguments
    this SysMLConnector.internal.CandidateStateMachine.Port
end
if this.Junction.Built && ~ this.Built
    this.StateflowObj = Stateflow.findMatchingPort(this.Junction.StateflowObj);
    %this.storeID();
    % no not store ID as it already exists
    % instead just set Built
    this.Built = true;
end
end