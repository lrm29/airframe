classdef Junction < XMIChecker.Validator.Default
    %JUNCTION state machine element validator

    methods
        function junctionValidatorObj = Junction(candidate,xmidb,foundElements)
            %JUNCTION Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateStateMachine.Junction
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            junctionValidatorObj@XMIChecker.Validator.Default(candidate,xmidb,foundElements);
            junctionValidatorObj.processBuildableFlag(candidate.Built);
        end
    end
end
