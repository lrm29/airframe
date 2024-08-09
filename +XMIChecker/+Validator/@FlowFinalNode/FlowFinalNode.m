classdef FlowFinalNode < XMIChecker.Validator.CandidateAD.Element
    %FLOWFINALNODE validates AD FlowFinalNodes
    methods
        function flowFinalNodeObj = FlowFinalNode(candidate,xmidb,foundElements)
            %FLOWFINALNODE Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateAD.FlowFinalNode
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call super constructor
            flowFinalNodeObj@XMIChecker.Validator.CandidateAD.Element(candidate,xmidb,foundElements);
        end
    end
end

