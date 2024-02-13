classdef Pin < xmi.CandidateAD.Element
    properties
        TokenType systemcomposer.activitydiagram.model.TokenType
        Direction systemcomposer.activitydiagram.model.PortDirection
        ReferenceID char
    end

    methods
        function pinObj = Pin(type, direction, parent, name, externalID)
            arguments
                type
                direction 
                parent xmi.CandidateAD.Node
                name
                externalID = [char(parent.ExternalID) '_' name];
            end

            % Ensure that the pin is given a unique name.
            if isempty(name)
                name = xmi.CandidateAD.internal.nextNameProperty(parent.Pins, 'Pin');
            else
                name = xmi.CandidateAD.internal.nextNameProperty(parent.Pins, name);
            end

            pinObj@xmi.CandidateAD.Element(Name=name, ExternalID=externalID, Parent=parent);
            pinObj.TokenType = type;
            pinObj.Direction = direction;
        end

        function  flow = connect(source, destination, guard, externalID)
            flow = xmi.CandidateAD.internal.connect(source, destination, guard, externalID);
        end

        function doPublish(this, target)
            if isequal(this.TokenType, systemcomposer.activitydiagram.model.TokenType.CONTROL)
                % Do not create control pins.
                return;
            end

            adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

            isInput = isequal(this.Direction, systemcomposer.activitydiagram.model.PortDirection.INPUT);

            try
                activityPath = xmi.CandidateAD.internal.getQualifiedName(target);

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

        function prePrint(~,~)
        end

        function postPrint(~,~)
        end

        function doPrint(this, printer)
            printStr = sprintf('%s: [%s, Type: %s, Direction: %s]', this.ElementType, this.Name, char(this.TokenType), char(this.Direction));
            printer.print(string(printStr));
        end
    end
end