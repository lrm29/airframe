classdef Allocation < SysMLImport.internal.CandidateAllocation.Element
    properties
        SourceID
        TargetID
        PrintString
    end

    properties (Dependent)
        AllocationSetName
        Source
        Target
        isValid
    end

    methods
        function allocObj = Allocation(sourceID, targetID, varargin)
            allocObj@SysMLImport.internal.CandidateAllocation.Element(varargin{:});
            
            allocObj.SourceID = sourceID;
            allocObj.TargetID = targetID;
        end

        function allocationSetName = get.AllocationSetName(this)
            allocationSetName = sprintf('%sTo%s_Allocations', SysMLImport.internal.utils.getModelName(this.Source.ZCElement), ...
                                                              SysMLImport.internal.utils.getModelName(this.Target.ZCElement));
        end

        function referenceElement = get.Source(this)
            referenceElement = [];
            if ~isempty(this.SourceID)
                referenceElement = SysMLImport.internal.CandidateElement.idMap(...
                                "lookup", this.SourceID);
            end
        end

        function referenceElement = get.Target(this)
            referenceElement = [];
            if ~isempty(this.TargetID)
                referenceElement = SysMLImport.internal.CandidateElement.idMap(...
                                "lookup", this.TargetID);
            end
        end

        function tf = get.isValid(this)
            tf = ~isempty(this.Source)           && ~isempty(this.Target)                 ...
              && ~isempty(this.Source.ZCElement) && ~isempty(this.Target.ZCElement)       ...
              &&  isvalid(this.Source.ZCElement) &&  isvalid(this.Target.ZCElement);
        end       

        function doPublish(this, varargin)
            sourceElement = this.getFinalElement(this.Source);
            targetElement = this.getFinalElement(this.Target);

            this.Parent.ZCElement.allocate(sourceElement, targetElement);

            % Cache the print string for later in case the model has been
            % closed.
            this.PrintString = sprintf('[Source: %s, Target: %s]', sourceElement.getQualifiedName, targetElement.getQualifiedName);
        end

        function finalElement = getFinalElement(~, element)
            % If the element is lifeline from a sequence diagram, get the
            % component representation of it.
            finalElement = element.ZCElement;
            if isa(element, 'SysMLImport.internal.CandidateInteraction.Lifeline')
                finalElement = finalElement.RelatedElements;
            end
        end

        function prePrint(~,~)
        end

        function postPrint(~,~)
        end

        function doPrint(this, printer)
            printer.print(this.PrintString);
        end
    end
end