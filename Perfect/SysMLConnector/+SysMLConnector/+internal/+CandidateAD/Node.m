classdef Node < SysMLConnector.internal.CandidateAD.Element & matlab.mixin.Heterogeneous
    properties
        Parameters
        Nodes
        Pins
        Flows
    end

    methods
        function nodeObj = Node(varargin)
            nodeObj@SysMLConnector.internal.CandidateAD.Element(varargin{:});
            nodeObj.ValidRequirementLinkTarget = true;
        end

        function node = addNode(modelObj, nodeName, nodeType, nodeID)
            switch nodeType
                case 'Initial'
                    node = SysMLConnector.internal.CandidateAD.InitialNode(Name=nodeName, ExternalID=nodeID, Parent=modelObj);
                case 'ActivityFinal'
                    node = SysMLConnector.internal.CandidateAD.FinalNode(Name=nodeName, ExternalID=nodeID, Parent=modelObj);
                case 'FlowFinal'
                    node = SysMLConnector.internal.CandidateAD.FlowFinalNode(Name=nodeName, ExternalID=nodeID, Parent=modelObj);
                case 'JoinFork'
                    node = SysMLConnector.internal.CandidateAD.JoinForkNode(Name=nodeName, ExternalID=nodeID, Parent=modelObj);
                case 'MergeDecision'
                    node = SysMLConnector.internal.CandidateAD.MergeDecisionNode(Name=nodeName, ExternalID=nodeID, Parent=modelObj);
                otherwise
                    % Assume Activity
                    node = SysMLConnector.internal.CandidateAD.Activity(Name=nodeName, ExternalID=nodeID, Parent=modelObj);
            end

            modelObj.Nodes = [modelObj.Nodes node];
        end

        function removeNode(modelObj, nodeName)
            nodeIdx = strcmp({modelObj.Nodes.Name}, nodeName);
            node = modelObj.Nodes(nodeIdx);
            delete(node);
            modelObj.Nodes(nodeIdx) = [];
        end

        function pin = addPin(this, name, type, direction, externalID)
            if isempty(name)
                name = SysMLConnector.internal.utils.nextNameProperty(this.Pins, 'Pin');
            end

            if nargin > 4
                pin = SysMLConnector.internal.CandidateAD.Pin(type, direction, this, name, externalID);
            else
                pin = SysMLConnector.internal.CandidateAD.Pin(type, direction, this, name);
            end

            this.Pins = [this.Pins pin];
        end

        function parameter = addParameter(this, name, type, direction, externalID)
            if isempty(name)
                name = SysMLConnector.internal.utils.nextNameProperty(this.Parameters, 'Parameter');
            end

            if nargin > 4
                parameter = SysMLConnector.internal.CandidateAD.Parameter(type, direction, this, name, externalID);
            else
                parameter = SysMLConnector.internal.CandidateAD.Parameter(type, direction, this, name);
            end

            this.Parameters = [this.Parameters parameter];
        end

        function flow = connect(source, destination, guard, externalID)
            flow = SysMLConnector.internal.CandidateAD.internal.connect(source, destination, guard, externalID);
        end

        function doPublish(this, target)    
            if isempty(this.ZCElement) || ~isvalid(this.ZCElement)
                this.ZCElement = SysMLConnector.internal.CandidateAD.internal.addAction(target, this.Name);
            end
        end

        function postPublish(this, ~)
            arrayfun(@(pin)  publish(pin,  this), this.Pins);
            arrayfun(@(parameter)  publish(parameter,  this), this.Parameters);
            arrayfun(@(node) publish(node, this), this.Nodes);
            arrayfun(@(flow) publish(flow, this), this.Flows);

            warnState = warning('off', 'diagram_autolayout:autolayout:layoutRejectedCommandLine');
            systemPath = SysMLConnector.internal.CandidateAD.internal.getArchitecturePeer(this.ZCElement).getQualifiedName;
            Simulink.BlockDiagram.arrangeSystem(systemPath);
            warning(warnState);
        end

        function doPrint(this, printer)
            printer.openScope("Parameters");
            arrayfun(@(elem) print(elem, printer), this.Parameters);
            printer.closeScope("Parameters");

            printer.openScope("Nodes");
            arrayfun(@(elem) print(elem, printer), this.Nodes);
            printer.closeScope("Nodes");

            printer.openScope("Pins");
            arrayfun(@(elem) print(elem, printer), this.Pins);
            printer.closeScope("Pins");
            
            printer.openScope("Flows");
            arrayfun(@(elem) print(elem, printer), this.Flows);
            printer.closeScope("Flows");
        end
    end
end