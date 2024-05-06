function syncElementID = getSyncElementID(pinElement, options)
    arguments
        pinElement = []
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

    fileName = pinElement.modelM3I.uri;
    elementID = SysMLConnector.internal.utils.getExtID(pinElement);

    useBackup = false;
    try
        xmiGraph = SysMLConnector.internal.XMIGraph.Graph.getGraph(fileName);
        if ~isempty(xmiGraph)    
            pinNode = xmiGraph.lookup(elementID);
            if ~isempty(pinNode) && hasProperty(pinNode, 'xmi_Extension') 
                xmiExtProp = pinNode.getProperty('xmi_Extension');
                
                if ~ismissing(xmiExtProp) && hasProperty(xmiExtProp, 'modelExtension')
                    mdlExtAttr = xmiExtProp.getProperty('modelExtension');

                    if ~ismissing(mdlExtAttr) && hasProperty(mdlExtAttr, 'syncElementAttribute')
                        syncElementID = getProperty(mdlExtAttr, 'syncElementAttribute');

                        if ismissing(syncElementID)
                            syncElementID = '';
                        end
                    end
                end
            end
        else
            useBackup = true;
        end
    catch ME
        warning('SysMLConnector:internal:utils:getSyncElementID:UnexpectedError', 'Unexpected error ''%s'' when trying to retrieve sync element ID.', ME.identifier);
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
end