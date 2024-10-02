classdef FinalNode < XMIChecker.Validator.CandidateAD.Element
    %FINALNODE validates AD FinalNodes
    
    methods
        function finalNodeObj = FinalNode(candidate,xmidb,foundElements)
            %FINALNODE Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateAD.FinalNode
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call super constructor
            finalNodeObj@XMIChecker.Validator.CandidateAD.Element(candidate,xmidb,foundElements);
        end
    end
end

