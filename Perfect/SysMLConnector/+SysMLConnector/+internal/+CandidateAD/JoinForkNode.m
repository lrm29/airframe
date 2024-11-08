classdef JoinForkNode < SysMLConnector.internal.CandidateAD.Node  
    methods
        function nodeObj = JoinForkNode(varargin)
            nodeObj@SysMLConnector.internal.CandidateAD.Node(varargin{:});

            if isempty(nodeObj.Name)
                nodeObj.Name = SysMLConnector.internal.utils.nextNameProperty(nodeObj.Owner.Nodes, 'JoinFork');
            end
        end

        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            this.BuiltElement = adCommands.addJoinFork(SysMLConnector.internal.CandidateAD.internal.getQualifiedName(target), this.Name);
        end
    end

    % <ProductSupportPackage><Protect/></ProductSupportPackage>
end