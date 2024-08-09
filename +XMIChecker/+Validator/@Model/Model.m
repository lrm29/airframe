classdef Model < XMIChecker.Validator.CandidateAD.Element
    %MODEL validates AD models
    methods
        function modelObj = Model(candidate,xmidb,foundElements)
            %MODEL Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateAD.Model
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call super constructor
            modelObj@XMIChecker.Validator.CandidateAD.Element(candidate,xmidb,foundElements);
        end
    end
end

