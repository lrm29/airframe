classdef Transition < XMIChecker.Validator.Utilities.Fake
    %TRANSITION validates state machine transitions
    
    methods
        function transitionValidatorObj = Transition(candidate,xmidb,foundElements)
            %TRANSITION Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateStateMachine.Transition
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            %% TODO: make real validator
            transitionValidatorObj@XMIChecker.Validator.Utilities.Fake(candidate);
        end
    end
end

