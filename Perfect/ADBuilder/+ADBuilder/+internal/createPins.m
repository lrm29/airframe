function createPins(node, pinStructs)
    if ~ismissing(pinStructs)
        for pinStruct = pinStructs
            pinName = '';
            if isfield(pinStruct, 'nameAttribute') && ~ismissing(pinStruct.nameAttribute)
                pinName = pinStruct.nameAttribute;
            end

            switch char(pinStruct.xmi_typeAttribute)
                case 'uml:InputPin'
                    portDirection = systemcomposer.activitydiagram.model.PortDirection.INPUT;
                case 'uml:OutputPin'
                    portDirection = systemcomposer.activitydiagram.model.PortDirection.OUTPUT;
                otherwise
                    error('ADBuilder:internal:createPins:UnhandledPinType', 'Unable to create unhandled pin type of ''%s'' for ''%s''.', pinStruct.xmi_typeAttribute, pinStruct.xmi_idAttribute);
            end

            % Add source object pins
            addPin(node, pinName, ...
                   systemcomposer.activitydiagram.model.TokenType.OBJECT, ...
                   portDirection, ...
                   pinStruct.xmi_idAttribute);
        end
    end
end