classdef JoinForkNode < xmi.CandidateAD.Node  
    methods
        function nodeObj = JoinForkNode(varargin)
            nodeObj@xmi.CandidateAD.Node(varargin{:});

            if isempty(nodeObj.Name)
                nodeObj.Name = xmi.CandidateAD.internal.nextNameProperty(nodeObj.Parent.Nodes, 'JoinFork');
            end
        end

        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            this.ZCElement = adCommands.addJoinFork(xmi.CandidateAD.internal.getQualifiedName(target), this.Name);
        end
    end
end