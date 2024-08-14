classdef StateMachine < XMIChecker.Validator.Validator
    %STATEMACHINE validates a state machine
    
    methods
        function stateMachineValidatorObj = StateMachine(candidate,xmidb,foundElements)
            %STATEMACHINE Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateStateMachine.StateMachine
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            stateMachineValidatorObj@XMIChecker.Validator.Validator(candidate);
            stateMachineValidatorObj.processBuildableFlag(candidate.Built);
        end
    end
end
