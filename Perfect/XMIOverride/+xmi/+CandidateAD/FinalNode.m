classdef FinalNode < xmi.CandidateAD.Node  
    methods
        function nodeObj = FinalNode(varargin)
            nodeObj@xmi.CandidateAD.Node(varargin{:});
            if isempty(nodeObj.Name)
                nodeObj.Name = 'ActivityFinal';
            end
        end

        function prePublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;
            this.ZCElement = adCommands.addActivityFinal(xmi.CandidateAD.internal.getQualifiedName(target), this.Name);
        end
    end
end