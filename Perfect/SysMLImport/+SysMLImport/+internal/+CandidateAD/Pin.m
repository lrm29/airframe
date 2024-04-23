classdef Pin < SysMLImport.internal.CandidateAD.Element
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
                parent SysMLImport.internal.CandidateAD.Node
                name
                externalID = [char(parent.ExternalID) '_' name];
            end

            % Ensure that the pin is given a unique name.
            if isempty(name)
                name = SysMLImport.internal.utils.nextNameProperty(parent.Pins, 'Pin');
            else
                name = SysMLImport.internal.utils.nextNameProperty(parent.Pins, name);
            end

            pinObj@SysMLImport.internal.CandidateAD.Element(Name=name, ExternalID=externalID, Parent=parent);
            pinObj.ValidRequirementLinkTarget = true;
            pinObj.TokenType = type;
            pinObj.Direction = direction;
        end

        function  flow = connect(source, destination, guard, externalID)
            flow = SysMLImport.internal.CandidateAD.internal.connect(source, destination, guard, externalID);
        end

        function doPublish(this, target)
            if isequal(this.TokenType, systemcomposer.activitydiagram.model.TokenType.CONTROL)
                % Do not create control pins.
                return;
            end

            isInput = isequal(this.Direction, systemcomposer.activitydiagram.model.PortDirection.INPUT);

            try
                activityPath = SysMLImport.internal.CandidateAD.internal.getQualifiedName(target);

                this.ZCElement = SysMLImport.internal.CandidateAD.internal.addPin(activityPath, this.Name, isInput);
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
            printStr = sprintf('%s: [Type: %s, Direction: %s]', this.Name, char(this.TokenType), char(this.Direction));
            printer.print(string(printStr));
        end
    end
end