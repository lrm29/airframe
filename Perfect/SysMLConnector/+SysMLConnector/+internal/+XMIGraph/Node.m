classdef Node < handle & matlab.mixin.CustomDisplay
    properties
        Owner
        Graph
        Name
        Type
        ID
        Properties
        Duplicates
        DuplicateOf
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
            nodeObj.Properties = dictionary;

            % Allow empty for use as a stub when the XMI parsing fails.
            if ~isempty(structure) 
                nodeObj.Struct = structure;
                nodeObj.Owner = options.Owner;
    
                register(nodeObj);
    
                nodeObj.visitChildren;
            end
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

                if ~isempty(nodeObj.DuplicateOf)
                    % This element is a duplicate of another element so add
                    % the property to the other element also.
                    addProperty(nodeObj.DuplicateOf, propertyName, propertyValue);
                end

                addProperty(nodeObj, propertyName, propertyValue);
            end
        end

        function addProperty(nodeObj, propertyName, propertyValue)
            if (nodeObj.Properties.numEntries > 0) && isKey(nodeObj.Properties, propertyName)
                try
                    existingValue = nodeObj.Properties{propertyName};
                    
                    if isequal(propertyValue, existingValue)
                        % The is the ideal case. If the property exists
                        % already then it is because there are duplicate
                        % XMI IDs in the imported file so if the properties
                        % have the same value, leave as-is, it is just
                        % redundant data.
                        return;
                    end

                    
                    % The values are different so try to concatenate them.
                    nodeObj.Properties(propertyName) = {nodeObj.Properties{propertyName} propertyValue};
                catch
                    % They can't so put them in a cell array.
                    existingProperties = nodeObj.Properties{propertyName};
                    if ~iscell(existingProperties)
                        existingProperties = {existingProperties};
                    end

                    newProperties = {{existingProperties {propertyValue}}};

                    nodeObj.Properties(propertyName) = newProperties;
                end
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
                propertyName {SysMLConnector.internal.utils.mustBeValidStructFieldName}
                propertyIdx = []
            end

            try
                propertyValue = nodeObj.Properties{propertyName};

                if iscell(propertyValue) && isscalar(propertyValue)
                    propertyValue = propertyValue{1};
                end
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