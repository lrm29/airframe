classdef Message < XMIChecker.Validator.Default
    %MESSAGE validates messages
    
    methods
        function messageValidatorObj = Message(candidate,xmidb,foundElements)
            %MESSAGE Construct an instance of this class
            arguments
                candidate SysMLConnector.internal.CandidateInteraction.Message
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call super
            messageValidatorObj@XMIChecker.Validator.Default(candidate,xmidb,foundElements);
            % check the flag
            messageValidatorObj.processBuildableFlag(candidate.Built);
        end
    end
end

