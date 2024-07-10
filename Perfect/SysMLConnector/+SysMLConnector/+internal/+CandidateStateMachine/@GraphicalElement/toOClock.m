function oClock = toOClock(oClock)
%TOOCLOCK bounds values to the range for indexing into OClock variables
arguments
    oClock {mustBeNumeric}
end
if isscalar(oClock)
    % make sure it is a whole number
    oClock = round(oClock);
    if oClock < 1
        % make sure it is a valid index
        oClock = oClock + 12;
    elseif oClock > 12
        % make sure it is not out of bounds
        oClock = mod(oClock,12);
    end
else
    oClock = arrayfun(...
        @(o) SysMLConnector.internal.CandidateStateMachine.Node.toOClock(o), ...
        oClock);
end