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
        obj.pass = 0;
        obj.fail = 1;
    end
    if obj.fail > 0
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

