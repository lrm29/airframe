function typeID = getStereotypePropertyTypeID(propertyElement, options)
    arguments
        propertyElement = []
        options.Reset logical = false
    end

    persistent fileData
    typeID = '';

    if isempty(fileData) || options.Reset
        fileData = containers.Map;

        if options.Reset
            return;
        end
    end

    fileName = propertyElement.modelM3I.uri;
    if ~isKey(fileData, fileName)
        fData.Contents = fileread(fileName);
        fData.FoundKeys = containers.Map;
        fileData(fileName) = fData;
    else
        fData = fileData(fileName);
    end

    if ~isKey(fData.FoundKeys, propertyElement.qualifiedName)
        fqnParts = string(split(propertyElement.qualifiedName, '.'));
        matchData = regexp(fData.Contents, ...
            "<[^>]*xmi:type='uml:Profile'[^>]*name='"              + fqnParts(1)      + ...
            "'[^>]*>.*?<[^>]*xmi:type='uml:Stereotype'[^>]*name='" + fqnParts(2)      + ...
            "'[^>]*>.*?<[^>]*xmi:type='uml:Property'[^>]*name='"   + fqnParts(3)      + ...
            "'[^>]*type='"                                         + "(?<typeID>\w*)" + ...
            "'[^>]*>.*?", 'names');
    
        if ~isempty(matchData) && ~isempty(matchData.typeID)
            typeID = matchData.typeID;
        end

        % Cache for faster indexing on subsequent calls.
        fData.FoundKeys(propertyElement.qualifiedName) = typeID;
        fileData(fileName) = fData;
    else
        typeID = fData.FoundKeys(propertyElement.qualifiedName);
    end
end