classdef InitialNode < SysMLImport.internal.CandidateAD.Node  
    methods
        function nodeObj = InitialNode(varargin)
            nodeObj@SysMLImport.internal.CandidateAD.Node(varargin{:});
            if isempty(nodeObj.Name)
                nodeObj.Name = 'Initial';
            end
        end

        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            this.ZCElement = adCommands.addInitial(SysMLImport.internal.CandidateAD.internal.getQualifiedName(target), this.Name);
        end
    end
end