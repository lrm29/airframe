function report(obj)
%REPORT prints out the results of the validator
arguments
    obj XMIChecker.Validator.Validator
end
if ~isempty(obj.candidate)
    if obj.fail > 0 || obj.warn > 0
        fields = fieldnames(obj.candidate);
        if ismember("Name",fields)
            name = obj.candidate.Name;
        else
            name = "";
        end
        if ismember("ExtElementID",fields)
            extElementID = obj.candidate.ExtElementID;
        else
            extElementID = "";
        end
        fprintf("Validation of %s: External ID:%s failures:%d warnings:%d\n", ...
            name,extElementID,obj.fail,obj.warn);
    end
end
end

