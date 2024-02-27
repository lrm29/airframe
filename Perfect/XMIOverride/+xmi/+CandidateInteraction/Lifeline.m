classdef Lifeline < xmi.CandidateInteraction.Element
    properties
        SourceID % The ID of the component/element that this lifeline represents
        FullPath
        Children
    end

    methods
        function lifelineObj = Lifeline(name, externalID, parent)
            lifelineObj@xmi.CandidateInteraction.Element(Name=name, ExternalID=externalID, Parent=parent);
        end

        function applyExternalUID(this)
            if ~isempty(this.ZCElement)
                this.ZCElement.RelatedElements.ExternalUID = this.ExtElementID;
            end            
        end

        function doPublish(this, varargin)
            this.ZCElement = xmi.CandidateInteraction.internal.addLifeline(this.Parent.ZCElement, this.Name);
        end
    end
end