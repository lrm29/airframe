classdef Fake < XMIChecker.Validator.Validator
    %FAKE fake validator that always returns pass
    
    methods
        function fakeValidatorObj = Fake(candidate)
            %FAKE Construct an instance of this class
            arguments
                candidate = [];
            end
            fakeValidatorObj@XMIChecker.Validator.Validator(candidate);
            warning("XMIChecker:Validator:Utilities:Fake",...
                "This is a fake validator. It will report pass always");
            fakeValidatorObj.pass = 1;
        end
    end
end

