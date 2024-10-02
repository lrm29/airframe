classdef MergeDecisionNode < XMIChecker.Validator.CandidateAD.Element
    %MERGEDECISIONSNODE validates AD merge decision nodes
    
    methods
        function mergeDecisionNode = MergeDecisionNode(candidate,xmidb,foundElements)
            %MERGEDECISIONSNODE Construct an instance of this class
             arguments
                candidate (1,1) SysMLConnector.internal.CandidateAD.MergeDecisionNode
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call super constructor
            mergeDecisionNode@XMIChecker.Validator.CandidateAD.Element(candidate,xmidb,foundElements);
        end
    end
end

