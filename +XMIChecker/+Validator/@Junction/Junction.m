classdef Junction < XMIChecker.Validator.Validator &... 
        XMIChecker.Validator.Utilities.Fake
    %JUNCTION state machine element validator

    methods
        function junctionValidatorObj = Junction(candidate,xmidb,foundElements)
            %JUNCTION Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateStateMachine.Junction
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            %% TODO: make real validator
            junctionValidatorObj@XMIChecker.Validator.Utilities.Fake(candidate);
        end
    end
end

