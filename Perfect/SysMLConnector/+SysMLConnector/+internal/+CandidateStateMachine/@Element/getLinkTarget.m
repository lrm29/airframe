function linkTarget = getLinkTarget(this)
%GETLINKTARGET provides the link target for elements of the state machine
arguments
    this SysMLConnector.internal.CandidateStateMachine.Element
end
linkTarget = this.BuiltElement;
end

