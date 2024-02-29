classdef JoinForkNode < SysMLImport.internal.CandidateAD.Node  
    methods
        function nodeObj = JoinForkNode(varargin)
            nodeObj@SysMLImport.internal.CandidateAD.Node(varargin{:});

            if isempty(nodeObj.Name)
                nodeObj.Name = SysMLImport.internal.CandidateAD.internal.nextNameProperty(nodeObj.Parent.Nodes, 'JoinFork');
            end
        end

        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            this.ZCElement = adCommands.addJoinFork(SysMLImport.internal.CandidateAD.internal.getQualifiedName(target), this.Name);
        end
    end
end