function moveCenterTo(this,newCenter)
arguments
    this SysMLConnector.internal.CandidateStateMachine.Junction
    newCenter (1,2) {mustBeNumeric}
end
if ~isempty(this.BuiltElement)
    this.BuiltElement.Position.Center = newCenter;
end
end