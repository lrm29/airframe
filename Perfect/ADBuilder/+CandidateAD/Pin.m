classdef Pin < CandidateAD.Element
    properties
        TokenType systemcomposer.activitydiagram.model.TokenType
        Direction systemcomposer.activitydiagram.model.PortDirection
    end

    methods
        function pinObj = Pin(type, direction, parent, name, externalID)
            arguments
                type
                direction 
                parent CandidateAD.Node
                name = ADBuilder.internal.nextNameProperty(parent.Pins, 'Pin');
                externalID = [char(parent.ExternalID) '_' name];
            end

            pinObj@CandidateAD.Element(Name=name, ExternalID=externalID, Parent=parent);
            pinObj.TokenType = type;
            pinObj.Direction = direction;
        end

        function flow = connect(sourcePin, destinationPin, guard, externalID)
            if isa(sourcePin.Parent, 'CandidateAD.Model')
                parent = sourcePin.Parent;
            else
                parent = sourcePin.Parent.Parent;
            end

            flow = CandidateAD.Flow(guard, sourcePin.ExternalID, destinationPin.ExternalID, Name='Conn', ExternalID=externalID, Parent=parent);

            parent.Flows = [parent.Flows flow];
        end

        function doPublish(this, target)
            if isequal(this.TokenType, systemcomposer.activitydiagram.model.TokenType.CONTROL)
                % Do not create control pins.
                return;
            end

            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            isInput = isequal(this.Direction, systemcomposer.activitydiagram.model.PortDirection.INPUT);

            try
                activityPath = ADBuilder.internal.getQualifiedName(target);

                this.ZCElement = adCommands.addPin(activityPath, this.Name, isInput);
            catch
                % Try to recover 
                if ~isa(target.ZCElement, 'systemcomposer.activitydiagram.model.Activity')
                    % Object Pins
                    this.ZCElement = this.Parent.ZCElement.Pins(strcmp({target.ZCElement.Pins.Name}, this.Name));
                else
                    % Activity Parameters
                    this.ZCElement = this.Parent.ZCElement.Parameters(strcmp({target.ZCElement.Parameters.Name}, this.Name));
                end
            end
        end
    end
end