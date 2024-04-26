function propertyValue = getStereotypePropertyValue(element, propertyFQN, options)
    arguments
        element = []
        propertyFQN = ''
        options.Reset logical = false
    end

    persistent fileData
    propertyValue = '';

    if isempty(fileData) || options.Reset
        fileData = containers.Map;

        if options.Reset
            return;
        end
    end

    fileName = element.modelM3I.uri;
    if ~isKey(fileData, fileName)
        fData.Contents = fileread(fileName);
        fData.FoundKeys = containers.Map;
        fileData(fileName) = fData;
    else
        fData = fileData(fileName);
    end
    
    elementID = SysMLConnector.internal.utils.getExtID(element);
    key = [char(elementID) '_' char(propertyFQN)];
    if ~isKey(fData.FoundKeys, key)
        % clean the fqn to be xml-compliant attribute names
        cleanPropertyFQN = SysMLConnector.internal.utils.cleanAttributeName(propertyFQN);
        fqnParts = string(split(cleanPropertyFQN, '.'));
        matchData = regexp(fData.Contents, ...
            "<" + fqnParts(1) + ":" + fqnParts(2) + ...
            "[^>]*base_(Class|Element)='" + elementID + ...
            "'[^>]*" + fqnParts(3) + "='" + ...
            "(?<propVal>[^']*)", 'names');
    
        if ~isempty(matchData) && ~isempty(matchData.propVal)
            propertyValue = matchData.propVal;
        end

        % Cache for faster indexing on subsequent calls.
        fData.FoundKeys(key) = propertyValue;
        fileData(fileName) = fData;
    else
        propertyValue = fData.FoundKeys(key);
    end
end