classdef FlowFinalNode < SysMLConnector.internal.CandidateAD.Node  
    methods
        function nodeObj = FlowFinalNode(varargin)
            nodeObj@SysMLConnector.internal.CandidateAD.Node(varargin{:});
            if isempty(nodeObj.Name)
                nodeObj.Name = 'FlowFinal';
            end
        end
        
        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;
            this.BuiltElement = adCommands.addFlowFinal(SysMLConnector.internal.CandidateAD.internal.getQualifiedName(target), this.Name);
        end
    end

    % <ProductSupportPackage><Protect/></ProductSupportPackage>
end