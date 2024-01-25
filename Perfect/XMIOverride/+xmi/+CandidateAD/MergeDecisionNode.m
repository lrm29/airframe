classdef MergeDecisionNode < xmi.CandidateAD.Node  
    properties
        ShowName (1,1) logical = false
    end

    methods
        function nodeObj = MergeDecisionNode(varargin)
            nodeObj@xmi.CandidateAD.Node(varargin{:});

            if isempty(nodeObj.Name)
                nodeObj.Name = xmi.CandidateAD.internal.nextNameProperty(nodeObj.Parent.Nodes, 'MergeDecision');
            else
                nodeObj.ShowName = true;
            end
        end

        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            this.ZCElement = adCommands.addMergeDecision(xmi.CandidateAD.internal.getQualifiedName(target), this.Name);
            this.ZCElement.NameVisible = this.ShowName;
        end
    end
end