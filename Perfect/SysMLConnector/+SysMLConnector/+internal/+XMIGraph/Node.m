classdef Node < handle & matlab.mixin.CustomDisplay
    properties
        % The -1 is an indicator to fetch the value (set on first
        % access for performance).
        Owner = -1
        Graph = []
        Name  = -1
        Type  = -1
        ID    = -1
        Duplicates  = -1
        DuplicateOf = -1
    end

    properties (Hidden)
        MWID
        Struct
        OwnedPropertyNames = -1
        PropertyNames = -1
        Properties  = -1
        XMIInitialized = false
    end

    methods (Access=?SysMLConnector.internal.XMIGraph.Graph)
        function nodeObj = Node(graph, elementID)
            if nargin > 0
                if isempty(graph)
                    nodeObj.Graph = nodeObj;
                else
                    nodeObj.Graph = graph;
                end

                nodeObj.MWID = elementID;    
            end
        end
    end

    methods
        function id = get.ID(nodeObj)
            initializeXMI(nodeObj);

            id = nodeObj.ID;
        end

        function duplicates = get.Duplicates(nodeObj)
            initializeXMI(nodeObj);

            duplicates = nodeObj.Duplicates;
        end

        function duplicateOf = get.DuplicateOf(nodeObj)
            initializeXMI(nodeObj);

            duplicateOf = nodeObj.DuplicateOf;
        end

        function name = get.Name(nodeObj)
            if ~ischar(nodeObj.Name)
                if isfield(nodeObj.Struct, 'nameAttribute')
                    nameID = nodeObj.Struct.nameAttribute;
                    nodeObj.Name = nodeObj.Graph.lookupByMWID(nameID);
                else
                    nodeObj.Name = '';
                end
            end

            name = nodeObj.Name;
        end

        function type = get.Type(nodeObj)
            if ~ischar(nodeObj.Type)
                if isfield(nodeObj.Struct, 'xmi_typeAttribute')
                    typeID = nodeObj.Struct.xmi_typeAttribute;
                    nodeObj.Type = nodeObj.Graph.lookupByMWID(typeID);
                else
                    nodeObj.Type = 'undefined';
                end
            end

            type = nodeObj.Type;
        end

        function owner = get.Owner(nodeObj)
            if nodeObj.Owner == -1
                owner = nodeObj.Graph.getOwner(nodeObj);
                nodeObj.Owner = owner;
            end

            owner = nodeObj.Owner;
        end

        function register(nodeObj)
            nodeObj.Graph.register(nodeObj);
        end

        function initializeXMI(nodeObj)
            if ~nodeObj.XMIInitialized
                % Set initialized now to prevent recursion.
                nodeObj.XMIInitialized = true;
                % Initialize the property fields
                nodeObj.ID = '';
                nodeObj.Duplicates = SysMLConnector.internal.XMIGraph.Node.empty;
                nodeObj.DuplicateOf = SysMLConnector.internal.XMIGraph.Node.empty;

                if isfield(nodeObj.Struct, 'xmi_idAttribute')
                    xmiID = nodeObj.Struct.xmi_idAttribute;
                    xmiIDValue = nodeObj.Graph.lookupByMWID(xmiID);
                    nodeObj.ID = xmiIDValue;
                    nodeObj.Graph.addElementsByXMI(xmiIDValue);
                end
            end
        end

        function initializeProperties(nodeObj)
            if ~isa(nodeObj.Properties, 'dictionary')
                nodeObj.PropertyNames = fieldnames(nodeObj.Struct)';
                nodeObj.OwnedPropertyNames = nodeObj.PropertyNames;

                for duplicateIdx = 1:numel(nodeObj.Duplicates)
                    nodeObj.PropertyNames = [nodeObj.PropertyNames fieldnames(nodeObj.Duplicates(duplicateIdx).Struct)'];
                end

                nodeObj.Properties = dictionary;
            end
        end

        function [tf, isOwned] = hasProperty(nodeObj, propertyName)
            initializeProperties(nodeObj);

            tf = ismember(propertyName, nodeObj.PropertyNames);
            isOwned = ismember(propertyName, nodeObj.OwnedPropertyNames);
        end

        function propertyValue = getProperty(nodeObj, propertyName, propertyIdx)
            arguments
                nodeObj
                propertyName {SysMLConnector.internal.utils.mustBeValidStructFieldName}
                propertyIdx = []
            end
            initializeProperties(nodeObj);

            [hasProp, isOwned] = hasProperty(nodeObj, propertyName);

            if hasProp
                if nodeObj.Properties.numEntries == 0 || ~isKey(nodeObj.Properties, propertyName)
                    % Property has not been initialized yet so initialize
                    % it now.

                    if isOwned
                        propertyValueIDs = nodeObj.Struct.(propertyName);
                        propertyValue = arrayfun(@(valueID) nodeObj.Graph.lookupByMWID(valueID), propertyValueIDs);
                    else
                        propertyValue = [];
                        
                        for duplicateIdx = 1:numel(nodeObj.Duplicates)
                            duplicate = nodeObj.Duplicates(duplicateIdx);

                            [~, isOwnedByDuplicate] = hasProperty(duplicate, propertyName);

                            if isOwnedByDuplicate
                                propertyValue = duplicate.getProperty(propertyName, propertyIdx);                                
                            end
                        end

                        if isempty(propertyValue)
                            % If it was not on the duplicate then something is
                            % wrong.
                            error('SysMLConnector:internal:XMIGraph:Node:UnretrievableProperty', 'Property ''%s'' could not be retrieved.', propertyName);
                        end
                    end

                    % Cache for faster retrieval next time
                    nodeObj.Properties(propertyName) = {propertyValue};

                else
                    propertyValue = nodeObj.Properties(propertyName);
                    propertyValue = [propertyValue{:}];
                end
            else
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
                nodeObj.Graph.initializeElement(nodeObj);

                propertyNames = string(properties(nodeObj)');
                propertyNames = setdiff(propertyNames, 'Properties');

                propList = struct;
                for propertyName = propertyNames
                    propList.(propertyName) = nodeObj.(propertyName);
                end

                for propertyName = nodeObj.PropertyNames
                    propertyName = string(propertyName); %#ok<FXSET>
                    propList.("p_" + propertyName) = getProperty(nodeObj, propertyName);
                end

                groups = matlab.mixin.util.PropertyGroup(propList);
            end
        end
    end
end