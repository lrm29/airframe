classdef InitialNode < SysMLConnector.internal.CandidateAD.Node  
    methods
        function nodeObj = InitialNode(varargin)
            nodeObj@SysMLConnector.internal.CandidateAD.Node(varargin{:});
            if isempty(nodeObj.Name)
                nodeObj.Name = 'Initial';
            end
        end

        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            this.BuiltElement = adCommands.addInitial(SysMLConnector.internal.CandidateAD.internal.getQualifiedName(target), this.Name);
        end
    end

    % <ProductSupportPackage><Protect/></ProductSupportPackage>
end