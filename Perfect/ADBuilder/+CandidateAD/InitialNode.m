classdef InitialNode < CandidateAD.Node  
    methods
        function nodeObj = InitialNode(varargin)
            nodeObj@CandidateAD.Node(varargin{:});
            if isempty(nodeObj.Name)
                nodeObj.Name = 'Initial';
            end
        end

        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            this.ZCElement = adCommands.addInitial(ADBuilder.internal.getQualifiedName(target), this.Name);
        end
    end
end