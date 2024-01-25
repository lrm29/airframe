function createPins(node, pinStruct)
    if isempty(pinStruct)
        return;
    end

    if isa(pinStruct, 'umlmm.SequenceOfElement')
        for pinIdx = 1:pinStruct.size
            xmi.CandidateAD.internal.createPins(node, pinStruct.at(pinIdx));
        end
    else
        pinName = '';
        pinID = xmi.utils.getExtID(pinStruct);

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
        addPin(node, pinName, ...
               systemcomposer.activitydiagram.model.TokenType.OBJECT, ...
               portDirection, ...
               pinID);
    end
end