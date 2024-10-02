classdef InitialNode < XMIChecker.Validator.CandidateAD.Element
    %INITIALNODE validates AD InitialNodes
    
    properties
        Property1
    end
    
    methods
        function initialNodeObj = InitialNode(candidate,xmidb,foundElements)
            %INITIALNODE Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateAD.InitialNode
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call super constructor
            initialNodeObj@XMIChecker.Validator.CandidateAD.Element(candidate,xmidb,foundElements);
        end
    end
end

