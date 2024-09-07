function S = auxParseXML(xmlFile)   
    arguments
        xmlFile (1,:) char {mustBeFile}
    end
    % Parse XML file
    xmlDoc = xmlread(xmlFile);
    
    % Convert XML document to MATLAB structure
    S = parseChildNodes(xmlDoc);

    % enter the root node to match behavior of readstruct.
    S = S.(char(fieldnames(S)));
end

function nodeStruct = parseChildNodes(theNode)
    % Recurse over node children
    childNodes = getChildNodes(theNode);
    numChildNodes = getLength(childNodes);

    nodeStruct = struct();

    % Handle attributes
    if hasAttributes(theNode)
        attributes = getAttributes(theNode);
        numAttributes = getLength(attributes);
        for count = 1:numAttributes
            attr = attributes.item(count-1);
            attrName = char(getName(attr));
            attrName = strrep(attrName, ':', '_');
            attrValue = string(getValue(attr));
            nodeStruct.([attrName 'Attribute']) = attrValue;
        end
    end
    
    if numChildNodes > 0    
        for count = 1:numChildNodes
            theChild = childNodes.item(count-1);
            nodeName = char(getNodeName(theChild));
    
            if strcmp(nodeName, '#text')
                %nodeName = 'Text';
                continue;
            end
    
            nodeName = strrep(nodeName, ':', '_');
    
            childStruct = parseChildNodes(theChild);
    
            % Reconcile the missing fields in the structures
            if isfield(nodeStruct, nodeName) && isstruct(nodeStruct.(nodeName))
                templateStruct = nodeStruct.(nodeName)(1);
    
                childFields    = string(fieldnames(childStruct)');
                templateFields = string(fieldnames(templateStruct)');
    
                [~, iTemplate, iChild] = setxor(templateFields, childFields);
                if ~isempty(iChild)
                    for childField = childFields(iChild)
                        [nodeStruct.(nodeName).(childField)] = deal(missing);
                    end
                end
                
                if ~isempty(iTemplate)
                    for templateField = templateFields(iTemplate)
                        childStruct.(templateField) = missing;
                    end
                end
    
                nodeStruct.(nodeName) = [nodeStruct.(nodeName) childStruct];
            else
                nodeStruct.(nodeName) = childStruct;
            end
        end
    end

    nodeFields = fieldnames(nodeStruct);
    if isempty(nodeFields)
        nodeStruct = strtrim(string(theNode.getTextContent.toString));
    elseif isscalar(nodeFields) && strcmp(nodeFields, "Text")
        nodeStruct = nodeStruct.Text;
    end
end