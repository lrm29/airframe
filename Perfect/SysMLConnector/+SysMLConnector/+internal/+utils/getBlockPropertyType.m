function [propertyType, propertyTypeName] = getBlockPropertyType(property, options)
    arguments
        property = ''
        options.Reset logical = false
        options.AttributeName = 'type'
        options.PropertyNode = SysMLConnector.internal.XMIGraph.Node.empty;
    end

    persistent fileData
    propertyType = '';
    propertyTypeName = '';

    attributeName = options.AttributeName;

    if isempty(fileData) || options.Reset
        fileData = containers.Map;

        if options.Reset
            return;
        end
    end

    try % Basic heuristic with no recovery. This function is a backup.
        fileName = property.rootModel.uri;
        elementID = SysMLConnector.internal.utils.getExtID(property);
    
        useBackup = false;
        try
            propertyElement = options.PropertyNode;
            if isempty(propertyElement)
                xmiGraph = SysMLConnector.internal.XMIGraph.Graph.getGraph(fileName);
                if ~isempty(xmiGraph)
                    propertyElement = xmiGraph.lookup(elementID);
                end

                % One more heuristic for stereotype property types.
                if isempty(propertyElement) ...
                    && isa(property, 'M3I.ImmutableProperty') ...
                    && isprop(property, 'qualifiedName') ...
                    && ~ismissing(string(property.qualifiedName))
                    
                    stereotypeParts = strsplit(property.qualifiedName, '.');

                    profile = [];
                    for profileIdx = 1:numel(xmiGraph.Profiles)
                        iterProfile = xmiGraph.Profiles(profileIdx);

                        if ismissing(iterProfile.Name)
                            continue;
                        end

                        if strcmp(iterProfile.Name, stereotypeParts{1})
                            profile = iterProfile;
                            break;
                        end
                    end

                    stereotype = [];
                    if ~isempty(profile)
                        stereotypes = profile.getProperty('packagedElement');

                        if ~ismissing(stereotypes)
                            for stereotypeIdx = 1:numel(stereotypes)
                                iterStereotype = stereotypes(stereotypeIdx);

                                if ismissing(iterStereotype.Name)
                                    continue;
                                end

                                if strcmp(iterStereotype.Name, stereotypeParts{2})
                                    stereotype = iterStereotype;
                                    break;
                                end
                            end
                        end
                    end

                    if ~isempty(stereotype)
                        properties = stereotype.getProperty('ownedAttribute');

                        if ~ismissing(properties)
                            for propertyIdx = 1:numel(properties)
                                iterProperty = properties(propertyIdx);

                                if ismissing(iterProperty.Name)
                                    continue;
                                end

                                if strcmp(iterProperty.Name, stereotypeParts{3})
                                    propertyElement = iterProperty;
                                    break;
                                end
                            end
                        end
                    end

                    
                end
            end
    
            if ~isempty(propertyElement)
                if hasProperty(propertyElement, [attributeName 'Attribute'])
                    propertyType = getProperty(propertyElement, [attributeName 'Attribute']);
                    
                    if ismissing(propertyType)
                        propertyType = '';
                    end
                end
        
                if isempty(propertyType) && hasProperty(propertyElement, attributeName) 
                    propertyTypeElement = getProperty(propertyElement, attributeName);
    
                    if ismissing(propertyTypeElement)
                        propertyType = '';
                    else
                        propertyType = getProperty(propertyTypeElement, 'hrefAttribute');
                    end
                end
            else
                useBackup = true;
            end
        catch ME
            warning('SysMLConnector:internal:utils:getBlockPropertyType:UnexpectedError1', 'Unexpected error (0x01) ''%s'' when trying to retrieve block property type (line %i).', ME.identifier, ME.stack(1).line);
            useBackup = true;
        end
    
        if useBackup
            % If the XMI graph cannot be built then use regex as a (slow)
            % backup.    
            if ~isKey(fileData, fileName)
                fData.Contents = fileread(fileName);
                fData.FoundKeys = containers.Map;
                fileData(fileName) = fData;
            else
                fData = fileData(fileName);
            end
        
            if ~isKey(fData.FoundKeys, elementID)
                matchData = regexp(fData.Contents, "<(?<tagName>\w+)[^>]*xmi:id='"+string(elementID)+"'(?<captureGroup>[^>]*(>.*?<"+string(attributeName)+"[^>]*href='(?<hrefType>[^']*)'[^>]*>.*?<\/\k<tagName>>)|([^>]*"+string(attributeName)+"='(?<type>\w+)'[^>]*\/>))", 'names');
            
                if ~isempty(matchData)
                    captureGroup = matchData.captureGroup;
        
                    hrefType = regexp(captureGroup, "<"+string(attributeName)+"[^>]*href='([^']*)'", 'tokens');
                    if ~isempty(hrefType)
                        propertyType = string(hrefType);
                    else
                        type = regexp(captureGroup, "[^>]*"+string(attributeName)+"='([^']*)'", 'tokens');
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


        % Try to create a usable type name if possible
        if ~isempty(propertyType)
            if endsWith(propertyType,        'SysML_dataType.String')
                propertyTypeName = 'Dtype:string';
            elseif endsWith(propertyType,    'SysML_dataType.Number')     ...
                   || endsWith(propertyType, 'SysML_dataType.Real')    ...
                   || endsWith(propertyType, 'SysML_dataType.Complex')
                propertyTypeName = 'Dtype:real';
            elseif endsWith(propertyType,    'SysML_dataType.Boolean')
                propertyTypeName = 'Dtype:boolean';
            elseif endsWith(propertyType,    'SysML_dataType.Integer')
                propertyTypeName = 'Dtype:integer';
            end
        end
    catch ME
        warning('SysMLConnector:internal:utils:getBlockPropertyType:UnexpectedError2', 'Unexpected error (0x02) ''%s'' when trying to retrieve block property type (line %i).', ME.identifier, ME.stack(1).line);
    end
end