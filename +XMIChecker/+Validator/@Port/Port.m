classdef Port < XMIChecker.Validator.Utilities.Fake
    %PORT validator for ports within a state machine
    
    methods
        function portObj = Port(candidate,xmidb,foundElements)
            %PORT Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateStateMachine.Port
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            %% TODO: make real validator
            portObj@XMIChecker.Validator.Utilities.Fake(candidate);
        end
    end
end

