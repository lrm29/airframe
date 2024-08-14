classdef Transition < XMIChecker.Validator.Validator
    %TRANSITION validates state machine transitions
    
    methods
        function transitionValidatorObj = Transition(candidate,xmidb,foundElements)
            %TRANSITION Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateStateMachine.Transition
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            transitionValidatorObj@XMIChecker.Validator.Validator(candidate);
            transitionValidatorObj.processBuildableFlag(candidate.Built);
        end
    end
end

