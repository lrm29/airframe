function addConnectionPoint(this,connectionPoint)
%ADDCONNECTIONPOINT allows states to report to the region when they create
%connection points so the ports can be linked by transitions
arguments
    this SysMLConnector.internal.CandidateStateMachine.Region
    connectionPoint SysMLConnector.internal.CandidateStateMachine.Port
end
if ~isempty(connectionPoint)
    this.Subvertexes([connectionPoint.ExtElementID]) = connectionPoint;
end
end

