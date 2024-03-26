classdef FinalNode < SysMLImport.internal.CandidateAD.Node  
    methods
        function nodeObj = FinalNode(varargin)
            nodeObj@SysMLImport.internal.CandidateAD.Node(varargin{:});
            if isempty(nodeObj.Name)
                nodeObj.Name = 'ActivityFinal';
            end
        end

        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;
            this.ZCElement = adCommands.addActivityFinal(SysMLImport.internal.CandidateAD.internal.getQualifiedName(target), this.Name);
        end
    end

    % <ProductSupportPackage><Protect/></ProductSupportPackage>
end