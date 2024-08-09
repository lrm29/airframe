classdef Flow < XMIChecker.Validator.CandidateAD.Element
    %FLOW validates AD flows
    
    methods
        function flowObj = Flow(candidate,xmidb,foundElements)
            %FLOW Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateAD.Flow
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call super constructor
            flowObj@XMIChecker.Validator.CandidateAD.Element(candidate,xmidb,foundElements);
        end
    end
end

