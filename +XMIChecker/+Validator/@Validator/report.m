function report(obj)
%REPORT prints out the results of the validator
arguments
    obj XMIChecker.Validator.Validator
end
if ~isempty(obj.candidate)
    if obj.fail > 0 || obj.warn > 0
        fprintf("Validation of %s: External ID:%s failures:%d warnings:%d\n", ...
            obj.candidate.Name,obj.candidate.ExtElementID,obj.fail,obj.warn);
    end
end
end

