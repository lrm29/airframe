classdef Node < handle & matlab.mixin.CustomDisplay
    properties
        Owner
        Graph
        Name
        Type
        ID
        Properties
    end

    properties (Hidden)
        Struct
    end

    methods
        function nodeObj = Node(structure, options)
            arguments
                structure
                options.Owner = []
            end

            nodeObj.Struct = structure;
            nodeObj.Owner = options.Owner;
            nodeObj.Properties = dictionary;

            register(nodeObj);

            nodeObj.visitChildren;             
        end

        function register(nodeObj)
            nodeObj.Graph = nodeObj.Owner.Graph;
            nodeObj.Graph.addElement(nodeObj);
        end

        function visitChildren(nodeObj)
            structProperties = string(fieldnames(nodeObj.Struct)');
            structProperties = setdiff(structProperties, {'xmi_idAttribute', 'nameAttribute', 'xmi_typeAttribute'});

            for propertyName = structProperties
                propertyValue = nodeObj.Struct.(propertyName);
                if isstruct(propertyValue)
                    propertyValues = propertyValue;
                    propertyValue = SysMLConnector.internal.XMIGraph.Node.empty(0, numel(propertyValues));
                    for propertyValueIdx = 1:numel(propertyValues)
                        propertyValue(propertyValueIdx) = SysMLConnector.internal.XMIGraph.Node(propertyValues(propertyValueIdx), Owner=nodeObj);
                    end
                end

                addProperty(nodeObj, propertyName, propertyValue);
            end
        end

        function addProperty(nodeObj, propertyName, propertyValue)
            if (nodeObj.Properties.numEntries > 0) && isKey(nodeObj.Properties, propertyName)
                nodeObj.Properties(propertyName) = [nodeObj.Properties.(propertyName) {propertyValue}];
            else
                nodeObj.Properties(propertyName) = {propertyValue};
            end
        end

        function tf = hasProperty(nodeObj, propertyName)
            tf = (nodeObj.Properties.numEntries > 0) && isKey(nodeObj.Properties, propertyName);
        end

        function propertyValue = getProperty(nodeObj, propertyName, propertyIdx)
            arguments
                nodeObj
                propertyName {mustBeValidVariableName}
                propertyIdx = []
            end

            try
                propertyValue = nodeObj.Properties{propertyName};
            catch
                error('SysMLConnector:internal:XMIGraph:Node:UndefinedProperty', 'Property ''%s'' does not exist.', propertyName);
            end

            if ~isempty(propertyIdx)
                try
                    propertyValue = propertyValue(propertyIdx);
                catch
                    error('SysMLConnector:internal:XMIGraph:Node:InvalidPropertyIndex', 'Invalid index, ''%s'' specified for property ''%s'' of size ''[%s]''.', strtrim(formattedDisplayText(propertyIdx)), propertyName, strtrim(formattedDisplayText(size(propertyValue))));
                end
            end
        end
    end

    methods (Access = protected)
        function groups = getPropertyGroups(nodeObj)
            if ~isscalar(nodeObj)
                groups = getPropertyGroups@matlab.mixin.CustomDisplay(nodeObj);
            else
                propertyNames = string(properties(nodeObj)');
                propertyNames = setdiff(propertyNames, 'Properties');

                propList = struct;
                for propertyName = propertyNames
                    propList.(propertyName) = nodeObj.(propertyName);
                end

                if nodeObj.Properties.numEntries > 0
                    for propertyName = string(nodeObj.Properties.keys)'
                        propList.("p_" + propertyName) = getProperty(nodeObj, propertyName);
                    end
                end

                groups = matlab.mixin.util.PropertyGroup(propList);
            end
        end
    end
end