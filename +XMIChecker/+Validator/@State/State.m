classdef State < XMIChecker.Validator.Validator
    %STATE validator for state element within a state machine 
    
    methods
        function stateObj = State(candidate,xmidb,foundElements)
            %STATE Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateStateMachine.State
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            stateObj@XMIChecker.Validator.Validator(candidate);
            stateObj.processBuildableFlag(candidate.Built);
        end
    end
end
