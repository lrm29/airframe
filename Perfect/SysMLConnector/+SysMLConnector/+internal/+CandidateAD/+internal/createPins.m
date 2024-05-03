function createPins(node, pinStruct, options)
    arguments
        node
        pinStruct
        options.CallBehaviorAction = false
    end

    if isempty(pinStruct)
        return;
    end

    if isa(pinStruct, 'umlmm.SequenceOfElement')
        for pinIdx = 1:pinStruct.size
            SysMLConnector.internal.CandidateAD.internal.createPins(node, pinStruct.at(pinIdx), CallBehaviorAction=options.CallBehaviorAction);
        end
    else
        pinName = '';
        pinID = SysMLConnector.internal.utils.getExtID(pinStruct);

        if ~isempty(pinStruct.name)
            pinName = pinStruct.name;
        end

        switch class(pinStruct)
            case 'umlmm.InputPin'
                portDirection = systemcomposer.activitydiagram.model.PortDirection.INPUT;
            case 'umlmm.OutputPin'
                portDirection = systemcomposer.activitydiagram.model.PortDirection.OUTPUT;
            otherwise
                error('xmi:CandidateAD:internal:createPins:UnhandledPinType', 'Unable to create unhandled pin type of ''%s'' for ''%s''.', class(pinStruct), pinID);
        end

        % Add source object pins
        pin = addPin(node, pinName, ...
                     systemcomposer.activitydiagram.model.TokenType.OBJECT, ...
                     portDirection, ...
                     pinID);

        if options.CallBehaviorAction
            pin.ReferenceID = SysMLConnector.internal.utils.getSyncElementID(pinStruct);
        end
    end
end