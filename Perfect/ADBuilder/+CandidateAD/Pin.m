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
                name
                externalID = [char(parent.ExternalID) '_' name];
            end

            % Ensure that the pin is given a unique name.
            if isempty(name)
                name = ADBuilder.internal.nextNameProperty(parent.Pins, 'Pin');
            else
                name = ADBuilder.internal.nextNameProperty(parent.Pins, name);
            end

            pinObj@CandidateAD.Element(Name=name, ExternalID=externalID, Parent=parent);
            pinObj.TokenType = type;
            pinObj.Direction = direction;
        end

        function  flow = connect(source, destination, guard, externalID)
            flow = ADBuilder.internal.connect(source, destination, guard, externalID);
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