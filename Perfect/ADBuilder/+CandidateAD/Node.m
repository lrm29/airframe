classdef Node < CandidateAD.Element & matlab.mixin.Heterogeneous
    properties
        Parameters
        Nodes
        Pins
        Flows
    end

    methods
        function nodeObj = Node(varargin)
            nodeObj@CandidateAD.Element(varargin{:});
        end

        function node = addNode(modelObj, nodeName, nodeType, nodeID)
            switch nodeType
                case 'Initial'
                    node = CandidateAD.InitialNode(Name=nodeName, ExternalID=nodeID, Parent=modelObj);
                case 'ActivityFinal'
                    node = CandidateAD.FinalNode(Name=nodeName, ExternalID=nodeID, Parent=modelObj);
                case 'FlowFinal'
                    node = CandidateAD.FlowFinalNode(Name=nodeName, ExternalID=nodeID, Parent=modelObj);
                case 'JoinFork'
                    node = CandidateAD.JoinForkNode(Name=nodeName, ExternalID=nodeID, Parent=modelObj);
                case 'MergeDecision'
                    node = CandidateAD.MergeDecisionNode(Name=nodeName, ExternalID=nodeID, Parent=modelObj);
                otherwise
                    % Assume Activity
                    node = CandidateAD.Activity(Name=nodeName, ExternalID=nodeID, Parent=modelObj);
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
                name = ADBuilder.internal.nextNameProperty(this.Pins, 'Pin');
            end

            if nargin > 4
                pin = CandidateAD.Pin(type, direction, this, name, externalID);
            else
                pin = CandidateAD.Pin(type, direction, this, name);
            end

            this.Pins = [this.Pins pin];
        end

        function parameter = addParameter(this, name, type, direction, externalID)
            if isempty(name)
                name = ADBuilder.internal.nextNameProperty(this.Parameters, 'Parameter');
            end

            if nargin > 4
                parameter = CandidateAD.Parameter(type, direction, this, name, externalID);
            else
                parameter = CandidateAD.Parameter(type, direction, this, name);
            end

            this.Parameters = [this.Parameters parameter];
        end

        function flow = connect(source, destination, guard, externalID)
            flow = ADBuilder.internal.connect(source, destination, guard, externalID);
        end

        function doPublish(this, target)    
            if isempty(this.ZCElement) || ~isvalid(this.ZCElement)
                this.ZCElement = ADBuilder.internal.addAction(target, this.Name);
            end
        end

        function postPublish(this, ~)
            arrayfun(@(pin)  publish(pin,  this), this.Pins);
            arrayfun(@(parameter)  publish(parameter,  this), this.Parameters);
            arrayfun(@(node) publish(node, this), this.Nodes);
            arrayfun(@(flow) publish(flow, this), this.Flows);

            warnState = warning('off', 'diagram_autolayout:autolayout:layoutRejectedCommandLine');
            systemPath = ADBuilder.internal.getArchitecturePeer(this.ZCElement).getQualifiedName;
            Simulink.BlockDiagram.arrangeSystem(systemPath);
            warning(warnState);
        end
    end
end