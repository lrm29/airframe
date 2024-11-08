classdef AllocationSet < SysMLConnector.internal.CandidateAllocation.Element
    properties
        Scenarios
    end

    properties % Build Artifacts
        Builder
        BuildSource
        BuildTarget
    end

    methods
        function modelObj = AllocationSet(varargin)
            modelObj@SysMLConnector.internal.CandidateAllocation.Element(varargin{:});
        end

        function setModel(this)
            this.Model = this;
        end

        function element = lookup(~, elementID)
            element = SysMLConnector.internal.CandidateElement.idMap("lookup", elementID);
        end

        function doPublish(this, varargin)
            if isempty(this.BuildName)
                this.BuildName = this.Builder.getModelName(this.Name);
            end

            this.BuiltElement = systemcomposer.allocation.createAllocationSet(this.BuildName, this.BuildSource, this.BuildTarget);

            % Immediately add it to the list so that it gets closed when
            % the builder is deleted, even if the build fails.
            this.Builder.AllocationSets = [this.Builder.AllocationSets this.BuiltElement];
            
            % Delete the default scenario.
            destroy(this.BuiltElement.Scenarios);
        end

        function scenario = addScenario(this, scenarioName, scenarioID)
            scenario = SysMLConnector.internal.CandidateAllocation.Scenario(Name=scenarioName, ExternalID=scenarioID, Owner=this);

            this.Scenarios = [this.Scenarios scenario];
        end

        function postPublish(this, varargin)
            arrayfun(@publish, this.Scenarios);           
        end

        function linkPackage(this)    
            if strcmp(this.OwnerExtElementID, "")
                % Derived allocation set. Set the package to match the
                % source.
                source = this.Scenarios(1).Allocations(1).Source;
                
                if isa(source, 'SysMLConnector.internal.CandidateArchitecture.CandidateArchitecture') ...
                        || isa(source, 'SysMLConnector.internal.CandidateArchitecture.CandidateComponent') ...
                        || isa(source, 'SysMLConnector.internal.CandidateArchitecture.CandidatePort') ...
                        || isa(source, 'SysMLConnector.internal.CandidateArchitecture.CandidateConnector')
                    this.OwnerExtElementID = source.OwnerExtElementID;
                else
                    this.OwnerExtElementID = source.Model.OwnerExtElementID;
                end
            end
            
            resolveOwningPackage(this);
            this.OwningPackage.BuildAllocations = [this.OwningPackage.BuildAllocations this];
        end

        function prelimBuild(~,~)
        end

        function finishBuild(~,~)
        end

        function prePrint(this, printer)
            printer.openScope("AllocationSet: " + this.Name);
        end

        function doPrint(this, printer)
            printer.openScope("Scenarios");
            arrayfun(@(elem) print(elem, printer), this.Scenarios);
            printer.closeScope("Scenarios");
        end

        function postPrint(this, printer)
            printer.closeScope("AllocationSet: " + this.Name);
        end
    end
end