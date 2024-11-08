classdef Allocation < SysMLConnector.internal.CandidateAllocation.Element
    properties
        SourceID
        TargetID
        PrintString
        Builder
    end

    properties (Dependent)
        AllocationSetName
        Source
        Target
        IsValid
    end

    methods
        function allocObj = Allocation(sourceID, targetID, varargin)
            allocObj@SysMLConnector.internal.CandidateAllocation.Element(varargin{:});
            
            allocObj.SourceID = sourceID;
            allocObj.TargetID = targetID;
        end

        function allocationSetName = get.AllocationSetName(this)
            allocationSetName = sprintf('Allocs_%sTo%s', SysMLConnector.internal.utils.getModelName(this.Source.BuiltElement), ...
                                                              SysMLConnector.internal.utils.getModelName(this.Target.BuiltElement));
        end

        function referenceElement = get.Source(this)
            referenceElement = [];
            if ~isempty(this.SourceID)
                referenceElement = SysMLConnector.internal.CandidateElement.idMap(...
                                "lookup", this.SourceID);
            end
        end

        function referenceElement = get.Target(this)
            referenceElement = [];
            if ~isempty(this.TargetID)
                referenceElement = SysMLConnector.internal.CandidateElement.idMap(...
                                "lookup", this.TargetID);
            end
        end

        function tf = get.IsValid(this)
            tf = false;

            try %#ok<TRYNC> Easier than trying to keep in sync with allowable allocation targets for the product.
                tf = ~isempty(this.Source)           && ~isempty(this.Target)                 ...
                  && ~isempty(this.Source.BuiltElement) && ~isempty(this.Target.BuiltElement)       ...
                  &&  isvalid(this.Source.BuiltElement) &&  isvalid(this.Target.BuiltElement);
            end
        end    

        function prePublish(this, varargin)
            % propagate downward for build.
            this.Builder = this.Owner.Builder;
        end

        function doPublish(this, varargin)
            try
                sourceElement = this.getFinalElement(this.Source);
                targetElement = this.getFinalElement(this.Target);

                this.Owner.BuiltElement.allocate(sourceElement, targetElement);
    
                % Cache the print string for later in case the model has been
                % closed.
                this.PrintString = sprintf('[Source: %s, Target: %s]', sourceElement.getQualifiedName, targetElement.getQualifiedName);
            catch ME
                addNotImported(this.Builder, this, this.ExtElementID, ME.message);
            end
        end

        function finalElement = getFinalElement(~, element)
            % If the element is lifeline from a sequence diagram, get the
            % component representation of it.
            finalElement = element.BuiltElement;
            if isa(element, 'SysMLConnector.internal.CandidateInteraction.Lifeline')
                finalElement = finalElement.RelatedElements;
            elseif startsWith(class(finalElement), 'systemcomposer.activitydiagram.model.')
                finalElement = SysMLConnector.internal.CandidateAD.internal.getArchitecturePeer(finalElement);
            end

            % Bubble up component architectures to components for allocation.
            if isa(finalElement, 'systemcomposer.arch.Architecture') ...
                    && ~isempty(finalElement.Parent) ...
                    && isa(finalElement.Parent, 'systemcomposer.arch.Component')
                finalElement = finalElement.Parent;
            end
        end

        function prePrint(~,~)
        end

        function postPrint(~,~)
        end

        function doPrint(this, printer)
            if this.Build
                printer.print(this.PrintString);
            end
        end
    end
end