classdef AllocationSet < SysMLImport.internal.CandidateAllocation.Element
    properties
        Scenarios
    end

    properties % Build Artifacts
        ParentPackage
        ParentPackageExtElementID
        BuildName
        BuildSource
        BuildTarget
    end

    methods
        function modelObj = AllocationSet(varargin)
            modelObj@SysMLImport.internal.CandidateAllocation.Element(varargin{:});
        end

        function setModel(this)
            this.Model = this;
        end

        function element = lookup(~, elementID)
            element = SysMLImport.internal.CandidateElement.idMap("lookup", elementID);
        end

        function doPublish(this, varargin)
            if isempty(this.BuildName)
                this.BuildName = matlab.lang.makeValidName(this.Name);
                % Deconflict filenames
                files = dir(pwd);
                [~, fileNames] = fileparts({files.name});
                this.BuildName = SysMLImport.internal.utils.nextName(fileNames, this.BuildName);    
            end
            
            modelName = this.BuildName;

            this.ZCElement = systemcomposer.allocation.createAllocationSet(modelName, this.BuildSource, this.BuildTarget);
            
            % Delete the default scenario.
            destroy(this.ZCElement.Scenarios);
        end

        function scenario = addScenario(this, scenarioName, scenarioID)
            scenario = SysMLImport.internal.CandidateAllocation.Scenario(Name=scenarioName, ExternalID=scenarioID, Parent=this);

            this.Scenarios = [this.Scenarios scenario];
        end

        function postPublish(this, varargin)
            arrayfun(@publish, this.Scenarios);           
        end

        function linkPackage(this)    
            if isempty(this.ParentPackageExtElementID)
                % Derived allocation set. Set the package to match the
                % source.
                this.ParentPackageExtElementID = this.Scenarios(1).Allocations(1).Source.Model.ParentPackageExtElementID;
            end

            compPkg = SysMLImport.internal.CandidateElement.idMap(...
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