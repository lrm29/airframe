classdef XMIVisitor < handle
    properties
        XmlStruct
        ElementDict
        ElementParentDict
        ElementTagNameDict
        XmiDict
        TypeDict
    end

    properties (Hidden)
        NextElementID = 0
    end

    methods
        function visitorObj = XMIVisitor(xmlStruct)
            visitorObj.XmlStruct = xmlStruct;
            
            visitorObj.ElementDict = dictionary;
            visitorObj.ElementDict(0) = {0};
            
            visitorObj.ElementParentDict = dictionary;
            visitorObj.ElementParentDict(0) = 0;
            
            visitorObj.ElementTagNameDict = dictionary;
            visitorObj.ElementTagNameDict(0) = '';

            visitorObj.XmiDict = dictionary;
            visitorObj.XmiDict('__root__') = {0}; % Cell because this one can have duplicates

            visitorObj.TypeDict = dictionary;
            visitorObj.TypeDict(0) = '';

            visitXMI(visitorObj, 0, 'XML', visitorObj.XmlStruct);
        end

        function nextID = getNextElementID(visitorObj)
            visitorObj.NextElementID = visitorObj.NextElementID + 1;
            nextID = visitorObj.NextElementID;
        end

        function elementID = visitXMI(visitorObj, parentID, tagName, xmlStruct)
            elementID = visitorObj.getNextElementID;

            visitorObj.ElementParentDict(elementID) = parentID;
            visitorObj.ElementTagNameDict(elementID) = tagName;
        
            if ~isstruct(xmlStruct)
                visitorObj.ElementDict(elementID) = {xmlStruct};
                return;
            end
        
            fields = fieldnames(xmlStruct)';
        
            xmiIDIndex = strcmp(fields, 'xmi_idAttribute');    
            if any(xmiIDIndex)
                xmiID = xmlStruct.xmi_idAttribute;
                if ~isKey(visitorObj.XmiDict, xmiID)
                    visitorObj.XmiDict(xmlStruct.xmi_idAttribute) = {elementID};
                else
                    existingElementIDs = [visitorObj.XmiDict{xmlStruct.xmi_idAttribute}];

                    visitorObj.XmiDict(xmlStruct.xmi_idAttribute) = {[existingElementIDs elementID]};
                end
            end

            xmiTypeIndex = strcmp(fields, 'xmi_typeAttribute');    
            if any(xmiTypeIndex)
                elementType = xmlStruct.xmi_typeAttribute;
            else
                elementType = "undefined";
            end
            visitorObj.TypeDict(elementID) = elementType;
        
            for fieldName = string(fields)
                subStruct = xmlStruct.(fieldName);
             
                mwIDs = strings(0, numel(subStruct));
                for fieldNum = 1:numel(subStruct)
                    mwIDs(fieldNum) = visitXMI(visitorObj, elementID, fieldName, subStruct(fieldNum));
                end
                xmlStruct.(fieldName) = mwIDs;
            end

            % update the cached struct with the property values replaced by
            % their element IDs
            visitorObj.ElementDict(elementID) = {xmlStruct};
        end

        function element = lookup(visitorObj, elementID)
            element = [visitorObj.ElementDict{elementID}];
        end

        function [elements, elementIDs] = lookupByXMI(visitorObj, xmiID)
            elements = [];
            elementIDs = [];
            if isKey(visitorObj.XmiDict, xmiID)
                elementIDs = [visitorObj.XmiDict{xmiID}];
                elements = visitorObj.ElementDict(elementIDs);
            end
        end

        function tagName = getTagNameByID(visitorObj, elementID)
            tagName = [];
            if isKey(visitorObj.ElementTagNameDict, elementID)
                tagName = visitorObj.ElementTagNameDict(elementID);
            end
        end

        function [parent, parentID] = getParentByID(visitorObj, elementID)
            parent = [];
            parentID = [];
            if isKey(visitorObj.ElementParentDict, elementID)
                parentID = visitorObj.ElementParentDict(elementID);
                parent = visitorObj.ElementDict(parentID);
            end
        end

        function elementIDs = getElementsByType(visitorObj, type)
            elementIDs = [];

            typeLogIndices = strcmp(visitorObj.TypeDict.values, type);
            if any(typeLogIndices)
                keys = visitorObj.TypeDict.keys;
                elementIDs = keys(typeLogIndices);
            end
        end
    end
end