classdef Port < XMIChecker.Validator.Validator
    %PORT validator for ports within a state machine
    
    methods
        function portObj = Port(candidate,xmidb,foundElements)
            %PORT Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateStateMachine.Port
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            portObj@XMIChecker.Validator.Validator(candidate);
            portObj.processBuildableFlag(candidate.Built);
        end
    end
end
