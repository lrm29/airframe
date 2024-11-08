function moveCenterTo(this,newCenter)
arguments
    this SysMLConnector.internal.CandidateStateMachine.Port
    newCenter (1,2) {mustBeNumeric}
end
this.Owner.moveCenterTo(newCenter);
end