function arrange(this)
%ARRANGE arranges this node and connected ones
arguments
    this SysMLConnector.internal.CandidateStateMachine.Port
end
% reset the arrange count and go again
this.ArrangeCount = 0;
arrange@SysMLConnector.internal.CandidateStateMachine.Node(this)
end
