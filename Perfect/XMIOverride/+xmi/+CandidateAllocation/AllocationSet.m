classdef AllocationSet < xmi.CandidateAllocation.Element
    properties
        Scenarios
    end

    properties % Build Artifacts
        ParentPackage
        ParentPackageExtElementID
        BuildName
        BuildSource
        BuildDestination
    end

    methods
        function modelObj = AllocationSet(varargin)
            modelObj@xmi.CandidateAllocation.Element(varargin{:});
        end

        function setModel(this)
            this.Model = this;
        end

        function element = lookup(~, elementID)
            element = xmi.CandidateElement.idMap("lookup", elementID);
        end

        function doPublish(this, varargin)
            if isempty(this.BuildName)
                this.BuildName = matlab.lang.makeValidName(this.Name);
                % Deconflict filenames
                files = dir(pwd);
                [~, fileNames] = fileparts({files.name});
                this.BuildName = xmi.CandidateAD.internal.nextName(fileNames, this.BuildName);    
            end
            
            modelName = this.BuildName;

            this.ZCElement = systemcomposer.allocation.createAllocationSet(modelName, this.BuildSource, this.BuildDestination);
        end

        function scenario = addScenario(this, scenarioName, scenarioID)
            scenario = xmi.CandidateAllocation.Scenario(Name=scenarioName, ExternalID=scenarioID, Parent=this);

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

            compPkg = xmi.CandidateElement.idMap(...
                "lookup", this.ParentPackageExtElementID);

            this.ParentPackage = compPkg;
        end

        function prelimBuild(~,~)
        end

        function finishBuild(~,~)
        end

        function prePrint(this, printer)
            printer.openScope("AllocationSet: " + this.Name);
        end

        function postPrint(this, printer)
            printer.closeScope("AllocationSet: " + this.Name);
        end
    end
end