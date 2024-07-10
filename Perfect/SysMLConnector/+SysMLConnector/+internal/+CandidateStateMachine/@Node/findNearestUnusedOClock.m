function oClock = findNearestUnusedOClock(this,oClock)
%FINDNEARESTUNUSEDOCLOCK finds the closest unused position
arguments
    this SysMLConnector.internal.CandidateStateMachine.Node
    oClock (1,1) {mustBeNumeric}
end
if this.OClocksInUse(oClock)
    % the most direct connection is in use need to find the
    % nearest
    for j = 1:round(numel(this.OClocksInUse)/2)
        % try values near the best until one is found
        tempOClock = this.toOClock([oClock + j,oClock - j]);
        tempOClock = tempOClock(~this.OClocksInUse(tempOClock));
        if ~isempty(tempOClock)
            oClock = tempOClock(1);
            break;
        end
    end
    % if no better option is found just go with the
    % original
end
end

