classdef Lifeline < SysMLImport.internal.CandidateInteraction.Element
    properties
        FullPath
        Children
    end

    methods
        function lifelineObj = Lifeline(name, externalID, parent)
            lifelineObj@SysMLImport.internal.CandidateInteraction.Element(Name=name, ExternalID=externalID, Parent=parent);
        end

        function applyExternalUID(this)
            if ~isempty(this.ZCElement)
                this.ZCElement.RelatedElements.ExternalUID = this.ExtElementID;
            end            
        end

        function doPublish(this, varargin)
            this.ZCElement = SysMLImport.internal.CandidateInteraction.internal.addLifeline(this.Parent.ZCElement, this.Name);
        end
    end
end