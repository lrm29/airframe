function moveCenterTo(this,newCenter)
%MOVECENTERTO moves the state to a center point
arguments
    this SysMLConnector.internal.CandidateStateMachine.State
    newCenter (1,2) {mustBeNumeric}
end
if ~isempty(this.BuiltElement)
    this.BuiltElement.Position(1) = newCenter(1) - (this.Width/2);
    this.BuiltElement.Position(2) = newCenter(2) - (this.Height/2);
end
end