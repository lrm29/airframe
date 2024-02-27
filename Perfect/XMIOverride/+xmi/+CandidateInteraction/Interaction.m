classdef Interaction < xmi.CandidateInteraction.Element
    properties
        Lifelines
        RootFragment
    end

    properties % Build Properties
        BuildName
        ParentPackage
        ParentPackageExtElementID
        ModelZCElement
    end

    methods
        function interObj = Interaction(name, externalID, parent)
            interObj@xmi.CandidateInteraction.Element(Name=name, ExternalID=externalID, Parent=parent);
        end

        function setModel(this)
            % method override during construction.
            this.Model = this;
        end

        function applyExternalUID(this)
            if ~isempty(this.ZCElement) && ~isempty(this.ExtElementID)
                % For now, one sequence diagram per arch model.
                this.ZCElement.Model.Architecture.ExternalUID = this.ExtElementID;
            end
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

            % Create as software architecture to model call/response via
            % client-server ports.
            this.ModelZCElement = systemcomposer.createModel(modelName, "SoftwareArchitecture");
            this.ZCElement = xmi.CandidateInteraction.internal.addInteraction(this.ModelZCElement, modelName);
        end

        function postPublish(this, varargin)
            arrayfun(@publish, this.Lifelines);

            Simulink.BlockDiagram.arrangeSystem(this.ZCElement.Name);
        end

        function lifeline = addLifeline(this, name, externalID)
            lifeline = xmi.CandidateInteraction.Lifeline(name, externalID, this);
            this.Lifelines = [this.Lifelines lifeline];
        end

        function linkPackage(this)            
            compPkg = xmi.CandidateElement.idMap(...
                "lookup", this.ParentPackageExtElementID);

            compPkg.addInteraction(this);

            this.ParentPackage = compPkg;
        end

        function prelimBuild(this, builder)
            builder.createInteraction(this);
        end

        function finishBuild(~,~)
        end

        function prePrint(this, printer)
            printer.openScope("SequenceDiagram: " + this.Name);
        end

        function postPrint(this, printer)
            printer.closeScope("SequenceDiagram: " + this.Name);
        end
    end
end