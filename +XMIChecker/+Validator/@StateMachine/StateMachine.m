classdef StateMachine < XMIChecker.Validator.Utilities.Fake
    %STATEMACHINE validates a state machine
    
    methods
        function stateMachineValidatorObj = StateMachine(candidate,xmidb,foundElements)
            %STATEMACHINE Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateStateMachine.StateMachine
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            %% TODO: make real validator
            stateMachineValidatorObj@XMIChecker.Validator.Utilities.Fake(candidate);
        end
    end
end

