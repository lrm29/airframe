classdef JoinForkNode < CandidateAD.Node  
    methods
        function nodeObj = JoinForkNode(varargin)
            nodeObj@CandidateAD.Node(varargin{:});

            if isempty(nodeObj.Name)
                nodeObj.Name = ADBuilder.internal.nextNameProperty(nodeObj.Parent.Nodes, 'JoinFork');
            end
        end

        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            this.ZCElement = adCommands.addJoinFork(ADBuilder.internal.getQualifiedName(target), this.Name);
        end
    end
end