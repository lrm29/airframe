classdef MergeDecisionNode < SysMLConnector.internal.CandidateAD.Node  
    properties
        ShowName (1,1) logical = false
    end

    methods
        function nodeObj = MergeDecisionNode(varargin)
            nodeObj@SysMLConnector.internal.CandidateAD.Node(varargin{:});

            if isempty(nodeObj.Name)
                nodeObj.Name = SysMLConnector.internal.utils.nextNameProperty(nodeObj.Parent.Nodes, 'MergeDecision');
            else
                nodeObj.ShowName = true;
            end
        end

        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            this.ZCElement = adCommands.addMergeDecision(SysMLConnector.internal.CandidateAD.internal.getQualifiedName(target), this.Name);
            this.ZCElement.NameVisible = this.ShowName;
        end
    end

    % <ProductSupportPackage><Protect/></ProductSupportPackage>
end