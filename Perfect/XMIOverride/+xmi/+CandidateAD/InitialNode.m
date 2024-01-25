classdef InitialNode < xmi.CandidateAD.Node  
    methods
        function nodeObj = InitialNode(varargin)
            nodeObj@xmi.CandidateAD.Node(varargin{:});
            if isempty(nodeObj.Name)
                nodeObj.Name = 'Initial';
            end
        end

        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            this.ZCElement = adCommands.addInitial(xmi.CandidateAD.internal.getQualifiedName(target), this.Name);
        end
    end
end