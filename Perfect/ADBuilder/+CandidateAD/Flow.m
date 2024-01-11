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

        function doPublish(this, target)
            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            if isequal(this.SourcePin.TokenType, systemcomposer.activitydiagram.model.TokenType.CONTROL)
                % Workaround for API not accepting slashes in component
                % names.
                origSystemName = target.ZCElement.Name;
                origSourceName = this.SourcePin.Parent.ZCElement.Name;
                origDestName   = this.DestinationPin.Parent.ZCElement.Name;

                cleanName = @(origName) strrep(origName, '/', 'FWD_SLASH'); 
                cleanSystemName = cleanName(origSystemName);
                cleanSourceName = cleanName(origSourceName);
                cleanDestName   = cleanName(origDestName);
                
                setZCName(target, cleanSystemName);
                setZCName(this.SourcePin.Parent, cleanSourceName);
                setZCName(this.DestinationPin.Parent, cleanDestName);

                this.ZCElement = adCommands.addFlow(ADBuilder.internal.getQualifiedName(target), ...
                                   this.SourcePin.Parent.ZCElement.Name, ...
                                   this.DestinationPin.Parent.ZCElement.Name);
                
                setZCName(target, origSystemName);
                setZCName(this.SourcePin.Parent, origSourceName);
                setZCName(this.DestinationPin.Parent, origDestName);                
            else
                if isequal(this.SourcePin.Parent.ZCElement, this.Parent.ZCElement)
                    % Architecture port
                    sourcePath = this.SourcePin.ZCElement.Name;
                else
                    sourcePath = [this.SourcePin.Parent.ZCElement.Name '/' this.SourcePin.ZCElement.Name];
                end

                if isequal(this.DestinationPin.Parent.ZCElement, this.Parent.ZCElement)
                    % Architecture port
                    destinationPath = this.DestinationPin.ZCElement.Name;
                else
                    destinationPath = [this.DestinationPin.Parent.ZCElement.Name '/' this.DestinationPin.ZCElement.Name];
                end

                this.ZCElement = adCommands.addFlow(ADBuilder.internal.getQualifiedName(target), ...
                                   sourcePath, ...
                                   destinationPath);
            end

            if ~isempty(this.Guard)
                setGuard(this.ZCElement, this.Guard);
            end
        end
    end
end