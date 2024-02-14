classdef Model < xmi.CandidateAD.Node
    properties
        BuildName
        ParentPackage
        ParentPackageExtElementID
        ModelDatabase
    end

    methods
        function modelObj = Model(varargin)
            modelObj@xmi.CandidateAD.Node(varargin{:});
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

            this.ZCElement = xmi.CandidateAD.internal.createActivity(modelName);
        end

        function setModel(this)
            % method override during construction.
            this.Model = this;
        end

        function linkPackage(this)            
            compPkg = xmi.CandidateElement.idMap(...
                "lookup", this.ParentPackageExtElementID);

            compPkg.addActivity(this);

            this.ParentPackage = compPkg;
        end

        function prelimBuild(this, builder)
            builder.createActivityDiagram(this);
        end

        function finishBuild(~,~)
        end

        function prePrint(this, printer)
            printer.openScope("ActivityDiagram: " + this.Name);
        end

        function postPrint(this, printer)
            printer.closeScope("ActivityDiagram: " + this.Name);
        end
    end
end