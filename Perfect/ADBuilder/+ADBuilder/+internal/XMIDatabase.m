classdef XMIDatabase < handle
    properties
        Source
        LookupTable
    end

    methods
        function xmiDBObj = XMIDatabase(umlStruct)
            xmiDBObj.Source = umlStruct;
            xmiDBObj.LookupTable = containers.Map;

            addStructToDB(xmiDBObj, umlStruct, '');
        end

        function addStructToDB(xmiDBObj, umlStruct, lookupPath)
            if isfield(umlStruct, 'xmi_idAttribute')
                if ~isKey(xmiDBObj.LookupTable, umlStruct.xmi_idAttribute)
                    xmiDBObj.LookupTable(umlStruct.xmi_idAttribute) = char(lookupPath);
                else
                    % Recursion detected.
                    return;
                end
            end

            fieldNames = fieldnames(umlStruct)';
            for fieldNameIdx = 1:numel(fieldNames)
                fieldName = fieldNames{fieldNameIdx};
                nextStructList = umlStruct.(fieldName);
                if isstruct(nextStructList)
                    for structIdx = 1:numel(nextStructList)
                        nextStruct = nextStructList(structIdx);
                        nextLookupPath = [lookupPath '.' fieldName '(' num2str(structIdx) ')'];
                        addStructToDB(xmiDBObj, nextStruct, nextLookupPath);
                    end
                end
            end
        end

        function result = lookup(xmiDBObj, xmiID)
            if isKey(xmiDBObj.LookupTable, xmiID)
                structPath = xmiDBObj.LookupTable(xmiID);
                result = eval(['xmiDBObj.Source' structPath]); %#ok<EVLDOT>
                result.XMI_Database = xmiDBObj;
            else
                result = [];
            end
        end

        function [elementPath, pathParts] = getElementPath(xmiDBObj, xmiID)
            structPath = xmiDBObj.LookupTable(xmiID);
            pattern = '\.(?<fieldName>\w+)\((?<index>\d+)\)';
            pathComponents = regexp(structPath, pattern, 'names');

            startStruct = xmiDBObj.Source;

            pathParts = strings(0,numel(pathComponents)+1);
            pathParts(1) = startStruct.nameAttribute;

            for pathComponentIdx = 1:numel(pathComponents)
                fieldName = pathComponents(pathComponentIdx).fieldName;
                index     = pathComponents(pathComponentIdx).index;
                startStruct = startStruct.(fieldName)(str2double(index));

                if ~isfield(startStruct, 'nameAttribute') || ismissing(startStruct.nameAttribute)
                    name = "unnamed_"+string(fieldName);
                else
                    name = startStruct.nameAttribute;
                end

                pathParts(pathComponentIdx+1) = name;
            end

            elementPath = strjoin(pathParts, '/');
        end
    end
       
end