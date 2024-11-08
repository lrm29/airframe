classdef Lifeline < SysMLConnector.internal.CandidateInteraction.Element & ...
        SysMLConnector.internal.CandidateInteraction.RelatedElementCommentable
    properties
        FullPath
        Children
    end

    methods
        function lifelineObj = Lifeline(name, externalID, parent)
            lifelineObj@SysMLConnector.internal.CandidateInteraction.Element(Name=name, ExternalID=externalID, Owner=parent);
        end

        function applyExternalUID(this)
            if ~isempty(this.BuiltElement)
                this.BuiltElement.RelatedElements.ExternalUID = this.ExtElementID;
            end            
        end

        function doPublish(this, varargin)
            this.BuiltElement = SysMLConnector.internal.CandidateInteraction.internal.addLifeline(this.Owner.BuiltElement, this.Name);
        end

        function linkTarget = getLinkTarget(this)
            linkTarget = [];
            
            if ~isempty(this.BuiltElement)
                linkTarget = this.BuiltElement.RelatedElements.SimulinkHandle;
            end
        end

        function print(this,printer)
            this.shortPrint(printer);
        end
    end
end