classdef Flow < CandidateAD.Element & matlab.mixin.Heterogeneous
    properties
        Guard (1,:) char
        SourcePinID (1,:) char
        DestinationPinID (1,:) char
    end

    properties (Dependent)
        SourcePin
        DestinationPin
    end

    methods
        function flowObj = Flow(guard, sourcePinID, destinationPinID, varargin)
            flowObj@CandidateAD.Element(varargin{:});

            flowObj.Guard = guard;
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
            % Check if the pins were created explicitely. If not, they will
            % be created by the flow function. 
            source = this.SourcePin;
            if isa(source, 'CandidateAD.Pin') && isempty(source.ZCElement)
                source = source.Parent;
            end

            destination = this.DestinationPin;
            if isa(destination, 'CandidateAD.Pin') && isempty(destination.ZCElement)
                destination = destination.Parent;
            end

            % Create the flow between the pins or nodes.
            this.ZCElement = ADBuilder.internal.addFlow( ...
                               source, ...
                               destination, ...
                               Guard=this.Guard);
        end
    end
end