function position = getOClockPosition(this,oClock)
%GETOCLOCKPOSITION determines position of the edge of the node in the
%OClock direction
arguments
    this SysMLConnector.internal.CandidateStateMachine.Node
    oClock {mustBeNumeric}
end
position = this.Center+this.Directions(oClock,:).*[this.Width,this.Height];
end

