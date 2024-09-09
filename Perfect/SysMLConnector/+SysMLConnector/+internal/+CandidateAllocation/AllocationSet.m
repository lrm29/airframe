classdef AllocationSet < SysMLConnector.internal.CandidateAllocation.Element
    properties
        Scenarios
    end

    properties % Build Artifacts
        ParentPackage
        ParentPackageExtElementID
        Builder
        BuildName
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

            this.ZCElement = systemcomposer.allocation.createAllocationSet(this.BuildName, this.BuildSource, this.BuildTarget);

            % Immediately add it to the list so that it gets closed when
            % the builder is deleted, even if the build fails.
            this.Builder.AllocationSets = [this.Builder.AllocationSets this.ZCElement];
            
            % Delete the default scenario.
            destroy(this.ZCElement.Scenarios);
        end

        function scenario = addScenario(this, scenarioName, scenarioID)
            scenario = SysMLConnector.internal.CandidateAllocation.Scenario(Name=scenarioName, ExternalID=scenarioID, Parent=this);

            this.Scenarios = [this.Scenarios scenario];
        end

        function postPublish(this, varargin)
            arrayfun(@publish, this.Scenarios);           
        end

        function linkPackage(this)    
            if isempty(this.ParentPackageExtElementID)
                % Derived allocation set. Set the package to match the
                % source.
                source = this.Scenarios(1).Allocations(1).Source;
                
                if isa(source, 'SysMLConnector.internal.CandidateArchitecture') ...
                        || isa(source, 'SysMLConnector.internal.CandidateComponent') ...
                        || isa(source, 'SysMLConnector.internal.CandidatePort') ...
                        || isa(source, 'SysMLConnector.internal.CandidateConnector')
                    this.ParentPackageExtElementID = source.ParentPackageExtElementID;
                else
                    this.ParentPackageExtElementID = source.Model.ParentPackageExtElementID;
                end
            end

            compPkg = SysMLConnector.internal.CandidateElement.idMap(...
                "lookup", this.ParentPackageExtElementID);

            this.ParentPackage = compPkg;
            this.ParentPackage.BuildAllocations = [this.ParentPackage.BuildAllocations this];
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