classdef Flow < SysMLConnector.internal.CandidateAD.Element & matlab.mixin.Heterogeneous
    properties
        Guard (1,:) char
        SourcePinID (1,:) char
        DestinationPinID (1,:) char
        PrintStr (1,:) char
    end

    properties (Dependent)
        SourcePin
        DestinationPin
    end

    methods
        function flowObj = Flow(guard, sourcePinID, destinationPinID, varargin)
            flowObj@SysMLConnector.internal.CandidateAD.Element(varargin{:});

            flowObj.Guard = string(guard);
            flowObj.SourcePinID = sourcePinID;
            flowObj.DestinationPinID = destinationPinID;
        end

        function sourcePin = get.SourcePin(flowObj)
            sourcePin = flowObj.Model.lookup(flowObj.SourcePinID);
        end

        function destinationPin = get.DestinationPin(flowObj)
            destinationPin = flowObj.Model.lookup(flowObj.DestinationPinID);
        end

        function doPublish(this, ~)
            this.PrintStr = '';

            % Check if the pins were created explicitly. If not, they will
            % be created by the flow function. 
            source = this.SourcePin;
            if isa(source, 'SysMLConnector.internal.CandidateAD.Pin') && isempty(source.BuiltElement)
                source = source.Owner;
            end

            destination = this.DestinationPin;
            if isa(destination, 'SysMLConnector.internal.CandidateAD.Pin') && isempty(destination.BuiltElement)
                destination = destination.Owner;
            end

            % Create the flow between the pins or nodes.
            flow = SysMLConnector.internal.CandidateAD.internal.addFlow( ...
                               source, ...
                               destination, ...
                               Guard=this.Guard);

            this.BuiltElement = flow;

            connector = SysMLConnector.internal.CandidateAD.internal.getArchitecturePeer(flow);
            
            % Create the print string before the model gets closed.
            this.PrintStr = sprintf('%s: [Type: %s, Guard: %s, Source: [%s].%s, Destination: [%s].%s]', ...
                    this.ElementType, ...
                    char(flow.flowType), ...
                    flow.Guard, ...
                    connector.SourcePort.Parent.Name, connector.SourcePort.Name, ...
                    connector.DestinationPort.Parent.Name, connector.DestinationPort.Name);
        end

        function prePrint(~,~)
        end

        function postPrint(~,~)
        end

        function doPrint(this, printer)
            printer.print(this.PrintStr);
        end
    end
end