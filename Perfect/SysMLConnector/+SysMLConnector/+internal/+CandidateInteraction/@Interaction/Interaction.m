classdef Interaction < SysMLConnector.internal.CandidateInteraction.Element & ...
        SysMLConnector.internal.CandidateInteraction.OperandReporter
    properties
        Lifelines
        RootFragment
        Messages
        LifeLineMap = dictionary();
        Fragments
        MessageMap = dictionary();
    end

    properties % Build Properties
        BuildName
        ParentPackage
        ParentPackageExtElementID
        ModelZCElement
    end

    methods
        function interObj = Interaction(name, externalID, parent)
            interObj@SysMLConnector.internal.CandidateInteraction.Element(Name=name, ExternalID=externalID, Parent=parent);
        end

        function setModel(this)
            % method override during construction.
            this.Model = this;
        end

        function linkTarget = getLinkTarget(this)
            linkTarget = [];
            
            if ~isempty(this.ModelZCElement)
                linkTarget = this.ModelZCElement.SimulinkHandle;
            end
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
                this.BuildName = SysMLConnector.internal.utils.nextName(fileNames, this.BuildName);    
            end
            
            modelName = this.BuildName;

            % Create as software architecture to model call/response via
            % client-server ports.
            this.ModelZCElement = systemcomposer.createModel(modelName, "SoftwareArchitecture");

            % Toggle allocation badges on
            set_param(this.ModelZCElement.SimulinkHandle, 'ShowAllocations', 'on')

            % Add the sequence diagram to the model
            this.ZCElement = SysMLConnector.internal.CandidateInteraction.internal.addInteraction(this.ModelZCElement, modelName);
        end

        function postPublish(this, varargin)
            arrayfun(@publish, this.Lifelines);
            arrayfun(@publish, this.Fragments);
            Simulink.BlockDiagram.arrangeSystem(this.ZCElement.Name);
        end

        function lifeline = addLifeline(this, name, externalID)
            lifeline = SysMLConnector.internal.CandidateInteraction.Lifeline(name, externalID, this);
            this.Lifelines = [this.Lifelines lifeline];
            this.LifeLineMap(externalID) = lifeline;
        end

        function linkPackage(this)            
            compPkg = SysMLConnector.internal.CandidateElement.idMap(...
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

        function doPrint(this, printer)
            % Only Lifelines for now.
            printer.openScope("Lifelines");
            arrayfun(@(elem) print(elem, printer), this.Lifelines);
            printer.closeScope("Lifelines");
        end

        function postPrint(this, printer)
            printer.closeScope("SequenceDiagram: " + this.Name);
        end

        message = addMessage(this,name,externalID,to,from);
        fragment = addFragment(this,element);
    end
end