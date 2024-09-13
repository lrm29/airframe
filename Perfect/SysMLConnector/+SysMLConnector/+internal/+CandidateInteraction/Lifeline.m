classdef Lifeline < SysMLConnector.internal.CandidateInteraction.Element & ...
        SysMLConnector.internal.CandidateInteraction.RelatedElementCommentable
    properties
        FullPath
        Children
    end

    methods
        function lifelineObj = Lifeline(name, externalID, parent)
            lifelineObj@SysMLConnector.internal.CandidateInteraction.Element(Name=name, ExternalID=externalID, Parent=parent);
        end

        function applyExternalUID(this)
            if ~isempty(this.ZCElement)
                this.ZCElement.RelatedElements.ExternalUID = this.ExtElementID;
            end            
        end

        function doPublish(this, varargin)
            this.ZCElement = SysMLConnector.internal.CandidateInteraction.internal.addLifeline(this.Parent.ZCElement, this.Name);
        end

        function linkTarget = getLinkTarget(this)
            linkTarget = [];
            
            if ~isempty(this.ZCElement)
                linkTarget = this.ZCElement.RelatedElements.SimulinkHandle;
            end
        end

        function print(this,printer)
            this.shortPrint(printer);
        end
    end
end