classdef Region < XMIChecker.Validator.Utilities.Fake
    %REGION state machine element validator
    
    
    methods
        function regionValidatorObj = Region(candidate,xmidb,foundElements)
            %REGION Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateStateMachine.Region
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            %% TODO: make real validator
            regionValidatorObj@XMIChecker.Validator.Utilities.Fake(candidate);
        end
    end
end

