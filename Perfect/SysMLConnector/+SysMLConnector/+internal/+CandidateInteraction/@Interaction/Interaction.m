classdef Interaction < SysMLConnector.internal.CandidateInteraction.Element & ...
        SysMLConnector.internal.CandidateInteraction.OperandReporter
    properties
        Lifelines
        RootFragment
        Messages
        LifelineMap = dictionary();
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

        function lifeline = getLifeline(this, lifelineExtID, umlElement) 
            % Get the lifeline from the interaction, create it if it does
            % not exist. umlElement is only used as a recovery heuristic
            % when the lifeline does not resolve.
            if (this.LifelineMap.numEntries > 0) && isKey(this.LifelineMap, lifelineExtID)
                lifeline = this.LifelineMap(lifelineExtID);
            elseif nargin > 2
                % Back-up heuristic to try to resolve the lifeline (mainly
                % for EA which does not always include all the lifelines in
                % the XMI).

                % Check if this heuristic already ran. The derived lifeline
                % needs to be tagged with this interaction ID to prevent
                % conflicts across the full import.
                derivedLifelineID = [char(this.ExtElementID) '___' char(lifelineExtID)];

                lifeline = this.getLifeline(derivedLifelineID);

                if isempty(lifeline)
                    % The derived lifeline has not been created yet so
                    % create it.
                    g = SysMLConnector.internal.XMIGraph.Graph.getGraph(umlElement.rootModel.uri);
                    xmiElement = g.lookup(lifelineExtID);
    
                    if ~isempty(xmiElement) && ~ismissing(xmiElement.Name)
                        name = xmiElement.Name;
                    else
                        name = 'lifeline';
                    end

                    lifeline = addLifeline(this, name, derivedLifelineID, char(lifelineExtID));
                end
            else
                lifeline = SysMLConnector.internal.CandidateInteraction.Lifeline.empty;
            end
        end

        function applyExternalUID(this)
            if ~isempty(this.ZCElement) && ~isempty(this.ExtElementID)
                % For now, one sequence diagram per arch model.
                this.ZCElement.Model.Architecture.ExternalUID = this.ExtElementID;
            end
        end

        function doPublish(this, zcModel)            
            modelName = this.BuildName;

            this.ModelZCElement = zcModel;

            % Toggle allocation badges on
            set_param(this.ModelZCElement.SimulinkHandle, 'ShowAllocations', 'on');

            % Add the sequence diagram to the model
            this.ZCElement = SysMLConnector.internal.CandidateInteraction.internal.addInteraction(this.ModelZCElement, modelName);
        end

        function postPublish(this, varargin)
            arrayfun(@publish, this.Lifelines);
            arrayfun(@publish, this.Fragments);
            Simulink.BlockDiagram.arrangeSystem(this.ZCElement.Name);
        end

        function lifeline = addLifeline(this, name, externalID, referenceID)
            lifeline = SysMLConnector.internal.CandidateInteraction.Lifeline(name, externalID, this);
            this.Lifelines = [this.Lifelines lifeline];
            this.LifelineMap(externalID) = lifeline;

            if nargin > 3
                lifeline.ReferenceElementID = referenceID;
    
                if ~isempty(referenceID)
                    % Capture the link between the lifeline and the referenced
                    % element as an allocation.
                    allocationID = sprintf('%s_%s', externalID, referenceID);
                    SysMLConnector.internal.CandidateAllocation.Allocation(externalID, referenceID, Name='', ExternalID=allocationID);
                end
            end
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
            % Print all that is printable
            this.print(printer);
        end

        function postPrint(this, printer)
            printer.closeScope("SequenceDiagram: " + this.Name);
        end

        message = addMessage(this,name,externalID,to,from);
        fragment = addFragment(this,element);
    end
end