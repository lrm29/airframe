classdef FinalNode < SysMLConnector.internal.CandidateAD.Node  
    methods
        function nodeObj = FinalNode(varargin)
            nodeObj@SysMLConnector.internal.CandidateAD.Node(varargin{:});
            if isempty(nodeObj.Name)
                nodeObj.Name = 'ActivityFinal';
            end
        end

        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;
            this.ZCElement = adCommands.addActivityFinal(SysMLConnector.internal.CandidateAD.internal.getQualifiedName(target), this.Name);
        end
    end

    % <ProductSupportPackage><Protect/></ProductSupportPackage>
end