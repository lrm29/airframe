function oClock = findClosestOClock(this,position)
%FINDCLOSESTOCLOCK finds the closest OClock position
arguments
    this SysMLConnector.internal.CandidateStateMachine.Node
    position (1,2) {mustBeNumeric}
end
[~,oClock] = min( ...
    sum( ...
    sqrt(([this.getOClockPosition(1:numel(this.OClocksInUse))]-position).^2) ...
    ,2));
end

