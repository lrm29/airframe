function moveCenterTo(this,newCenter)
arguments
    this SysMLConnector.internal.CandidateStateMachine.Junction
    newCenter (1,2) {mustBeNumeric}
end
if ~isempty(this.StateflowObj)
    this.StateflowObj.Position.Center = newCenter;
end
end