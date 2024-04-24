function propertyType = getBlockPropertyType(property, options)
    arguments
        property = ''
        options.Reset logical = false
    end

    persistent fileData
    propertyType = '';

    if isempty(fileData) || options.Reset
        fileData = containers.Map;

        if options.Reset
            return;
        end
    end

    fileName = property.rootModel.uri;

    if ~isKey(fileData, fileName)
        fData.Contents = fileread(fileName);
        fData.FoundKeys = containers.Map;
        fileData(fileName) = fData;
    else
        fData = fileData(fileName);
    end

    elementID = SysMLImport.internal.utils.getExtID(property);

    if ~isKey(fData.FoundKeys, elementID)
        matchData = regexp(fData.Contents, "<(?<tagName>\w+)[^>]*xmi:id='"+string(elementID)+"'(?<captureGroup>[^>]*(>.*?<type[^>]*href='(?<hrefType>[^']*)'[^>]*>.*?<\/\k<tagName>>)|([^>]*type='(?<type>\w+)'[^>]*\/>))", 'names');
    
        if ~isempty(matchData)
            captureGroup = matchData.captureGroup;

            hrefType = regexp(captureGroup, "<type [^>]*href='([^']*)'", 'tokens');
            if ~isempty(hrefType)
                propertyType = string(hrefType);
            else
                type = regexp(captureGroup, "[^>]*type='([^']*)'", 'tokens');
                if ~isempty(type)
                    propertyType = string(type);
                end
            end
        end

        % Cache for faster indexing on subsequent calls.
        fData.FoundKeys(elementID) = propertyType;
        fileData(fileName) = fData;
    else
        propertyType = fData.FoundKeys(elementID);
    end
end