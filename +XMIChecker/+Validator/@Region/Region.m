classdef Region < XMIChecker.Validator.Validator
    %REGION state machine element validator

    properties (SetAccess=protected)
        ParentValidator
    end
    
    methods
        function regionValidatorObj = Region(candidate,xmidb,foundElements)
            %REGION Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateStateMachine.Region
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % first store the candidate
            regionValidatorObj.candidate = candidate;
            % validate the parent as regions aren't directly represented
            regionValidatorObj.ParentValidator = ...
                XMIChecker.Validator.build(...
                candidate.Parent,xmidb,foundElements);
            % now report its results instead
            regionValidatorObj.pass = regionValidatorObj.ParentValidator.pass;
            regionValidatorObj.warn = regionValidatorObj.ParentValidator.warn;
            regionValidatorObj.fail = regionValidatorObj.ParentValidator.fail;
        end
    end
end

