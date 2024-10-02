function moveCenterTo(this,newCenter)
arguments
    this SysMLConnector.internal.CandidateStateMachine.Port
    newCenter (1,2) {mustBeNumeric}
end
this.Parent.moveCenterTo(newCenter);
end