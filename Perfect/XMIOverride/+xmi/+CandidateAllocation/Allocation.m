classdef Allocation < xmi.CandidateAllocation.Element
    properties
        SourceID
        DestinationID
    end

    properties (Dependent)
        AllocationSetName
        Source
        Destination
        isValid
    end

    methods
        function allocObj = Allocation(sourceID, destinationID, varargin)
            allocObj@xmi.CandidateAllocation.Element(varargin{:});
            
            allocObj.SourceID      = sourceID;
            allocObj.DestinationID = destinationID;
        end

        function allocationSetName = get.AllocationSetName(this)
            allocationSetName = sprintf('%sTo%s_Allocations', xmi.utils.getModelName(this.Source.ZCElement), ...
                                                              xmi.utils.getModelName(this.Destination.ZCElement));
        end

        function referenceElement = get.Source(this)
            referenceElement = [];
            if ~isempty(this.SourceID)
                referenceElement = xmi.CandidateElement.idMap(...
                                "lookup", this.SourceID);
            end
        end

        function referenceElement = get.Destination(this)
            referenceElement = [];
            if ~isempty(this.DestinationID)
                referenceElement = xmi.CandidateElement.idMap(...
                                "lookup", this.DestinationID);
            end
        end

        function tf = get.isValid(this)
            tf = ~isempty(this.Source)           && ~isempty(this.Destination)                 ...
              && ~isempty(this.Source.ZCElement) && ~isempty(this.Destination.ZCElement)       ...
              &&  isvalid(this.Source.ZCElement) &&  isvalid(this.Destination.ZCElement);
        end       

        function doPublish(this, varargin)
            sourceElement      = this.getFinalElement(this.Source);
            destinationElement = this.getFinalElement(this.Destination);

            this.Parent.ZCElement.allocate(sourceElement, destinationElement);
        end

        function finalElement = getFinalElement(~, element)
            % If the element is lifeline from a sequence diagram, get the
            % component representation of it.
            finalElement = element.ZCElement;
            if isa(element, 'xmi.CandidateInteraction.Lifeline')
                finalElement = finalElement.RelatedElements;
            end
        end

        function prePrint(~,~)
        end

        function postPrint(~,~)
        end

        function doPrint(this, printer)
            printStr = sprintf('[Source: %s, Destination: %s]', char(this.Source.ZCElement.getQualifiedName), char(this.Destination.ZCElement.getQualifiedName));
            printer.print(string(printStr));
        end
    end
end