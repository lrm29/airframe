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
    % clean the FQN to be XML-compliant attribute names
    cleanPropertyFQN = SysMLConnector.internal.utils.cleanAttributeName(propertyFQN);
    fqnParts = string(split(cleanPropertyFQN, '.'));

    % Get the stereotype application
    stereotypeObject = element.getOne("extension_" + fqnParts(1) + "." + fqnParts(2));

    if isempty(stereotypeObject)
        return;
    end

    stereotypeApplicationID = SysMLConnector.internal.utils.getExtID(stereotypeObject);

    useBackup = false;
    try
        xmiGraph = SysMLConnector.internal.XMIGraph.Graph.getGraph(fileName);
        if ~isempty(xmiGraph)    
            propertyName = fqnParts(3)+"Attribute";

            stereotypeApplicationElement = xmiGraph.lookup(stereotypeApplicationID);
            if ~isempty(stereotypeApplicationElement) && hasProperty(stereotypeApplicationElement, propertyName)
                propertyValue = getProperty(stereotypeApplicationElement, propertyName);

                if ismissing(propertyValue)
                    propertyValue = '';
                end
            end
        else
            useBackup = true;
        end
    catch ME
        warning('SysMLConnector:internal:utils:getStereotypePropertyValue:UnexpectedError', 'Unexpected error ''%s'' when trying to retrieve stereotype value.', ME.identifier);
        useBackup = true;
    end

    if useBackup
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
            matchData = regexp(fData.Contents, ...
                "<(?<tagName>\w+)[^>]*xmi:id='"+ stereotypeApplicationID + ...
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
end