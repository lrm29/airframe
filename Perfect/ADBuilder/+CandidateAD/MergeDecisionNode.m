classdef MergeDecisionNode < CandidateAD.Node  
    properties
        ShowName (1,1) logical = false
    end

    methods
        function nodeObj = MergeDecisionNode(varargin)
            nodeObj@CandidateAD.Node(varargin{:});

            if isempty(nodeObj.Name)
                nodeObj.Name = ADBuilder.internal.nextNameProperty(nodeObj.Parent.Nodes, 'MergeDecision');
            else
                nodeObj.ShowName = true;
            end
        end

        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            this.ZCElement = adCommands.addMergeDecision(ADBuilder.internal.getQualifiedName(target), this.Name);
            this.ZCElement.NameVisible = this.ShowName;
        end
    end
end