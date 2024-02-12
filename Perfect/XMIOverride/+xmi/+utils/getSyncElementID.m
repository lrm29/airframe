function syncElementID = getSyncElementID(fileName, elementID, options)
    arguments
        fileName char = ''
        elementID char = ''
        options.Reset logical = false
    end

    persistent fileData
    syncElementID = '';

    if isempty(fileData) || options.Reset
        fileData = containers.Map;

        if options.Reset
            return;
        end
    end

    if ~isKey(fileData, fileName)
        fData.Contents = fileread(fileName);
        fData.FoundKeys = containers.Map;
        fileData(fileName) = fData;
    else
        fData = fileData(fileName);
    end

    if ~isKey(fData.FoundKeys, elementID)
        matchData = regexp(fData.Contents, "<(?<tagName>\w+)[^>]*xmi:id='"+string(elementID)+"'[^>]*>.*?<xmi:Extension[^>]*>.*?<modelExtension[^>]*syncElement='(?<syncElementID>.*?)'[^>]*>.*?<\/xmi:Extension>.*?<\/\k<tagName>>", 'names');
    
        if ~isempty(matchData) && ~isempty(matchData.syncElementID)
            syncElementID = matchData.syncElementID;
        end

        % Cache for faster indexing on subsequent calls.
        fData.FoundKeys(elementID) = syncElementID;
        fileData(fileName) = fData;
    else
        syncElementID = fData.FoundKeys(elementID);
    end
end