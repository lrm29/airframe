function processBuildableFlag(obj,flag)
%PROCESSBUILDABLEFLAG processes the flag to determine if the existing
%result is correct or not
% if an element is not buildable but is built this is a failure, just as a
% missing buildable element is
arguments
    obj XMIChecker.Validator.Validator
    flag logical
end
if flag
    % means the candidate is expected to be built
    if obj.pass > 0
        % do nothing this is expected
    end
    if obj.fail > 0
        % this is not expected, but still means a failure
        % add a warning since this was reported as buildable
        obj.warn = obj.warn + 1;
    end
    if obj.warn > 0
        % this means something weird, given that the flag is set nothing to
        % add here
    end
else
    % do not expect candidate to be built 
    if obj.pass > 0
        % this means it was not buildable but was built...
        if isa(obj.candidate,"SysMLConnector.internal.CandidateElement")
            % if it is a candidate we can check for duplicates
            candidates = SysMLConnector.internal.CandidateElement.idMap("lookup", ...
                obj.candidate.ExtElementID);
            if numel(candidates) > 1
                % if there are duplicates check if any of those were built
                if any([candidates.Built])
                    % assume that one was built correctly and this
                    % candidate should pass
                    return
                else
                    % add warnings for the duplicates, but fail anyways
                    obj.warn = numel(candidates);
                end
            end
        end
        obj.pass = 0;
        obj.fail = 1;
    elseif obj.fail > 0 % use elseif as can only be pass or fail
        % this is actually the expected result, it isn't buildable and
        % wasn't built
        obj.fail = 0;
        obj.pass = obj.pass + 1;
    end
    if obj.warn > 0
        % again means something weird, no clear way to add infomration here
    end
end
end

