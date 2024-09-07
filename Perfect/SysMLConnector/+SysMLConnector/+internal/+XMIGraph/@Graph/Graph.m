classdef Graph < SysMLConnector.internal.XMIGraph.Node
    properties
        Profiles
        IDMap
        TypeMap
    end

    properties (Hidden)
        NextElementID = 1
    end

    methods  (Access=protected)
        function graphObj = Graph(name, structure)
            arguments
                name      = ''
                structure = ''
            end
            % If name and structure are empty, the XMI parsing failed and
            % this object is just a stub.

            graphObj@SysMLConnector.internal.XMIGraph.Node(structure);
            graphObj.ID = name;
            [~, graphObj.Name] = fileparts(name);
        end
    end

    methods
        function addElement(graphObj, element)
            if ~isfield(element.Struct, 'xmi_idAttribute')
                element.ID = ['Element_' num2str(graphObj.NextElementID)];
                graphObj.NextElementID = graphObj.NextElementID + 1;
            else
                element.ID = element.Struct.xmi_idAttribute;
            end

            if isfield(element.Struct, 'nameAttribute')
                element.Name = element.Struct.nameAttribute;
            end

            if isfield(element.Struct, 'xmi_typeAttribute')
                element.Type = element.Struct.xmi_typeAttribute;

                if strcmp(element.Type, 'uml:Profile')
                    graphObj.Profiles = [graphObj.Profiles element];
                end
            else
                element.Type = 'undefined';
            end

            if (graphObj.IDMap.numEntries > 0) && isKey(graphObj.IDMap, element.ID)
                % Track elements with duplicate IDs.
                existingElement = graphObj.IDMap(element.ID);
                existingElement.Duplicates = [existingElement.Duplicates element];
                element.DuplicateOf = existingElement;
            else
                graphObj.IDMap(element.ID) = element;
            end

            % Used for quick search by type.
            if (graphObj.TypeMap.numEntries > 0) && isKey(graphObj.TypeMap, element.Type)
                existingElements = graphObj.TypeMap(element.Type);
                existingElements = [existingElements{1}];
            else
                existingElements = [];
            end

            graphObj.TypeMap(element.Type) = {[existingElements element]};
        end

        function elements = getElementsByType(graphObj, xmiType)
            elements = [];
            try %#ok<TRYNC> do not slow this down with extra checks. If it does not work, return empty.
                if (nargin < 2) || isempty(xmiType)
                    elements = graphObj.TypeMap.values;
                else
                    elements = graphObj.TypeMap(xmiType);
                end

                if ~isempty(elements)
                    elements = [elements{:}];
                end
            end
        end

        function element = lookup(graphObj, elementID)
            element = [];
            try %#ok<TRYNC> do not slow this down with extra checks. If it does not work, return empty.
                element = graphObj.IDMap(elementID);
            end
        end

        function register(graphObj)
            graphObj.Graph   = graphObj;
            graphObj.IDMap   = dictionary;
            graphObj.TypeMap = dictionary;
        end
    end

    methods (Static)
        graphObj = getGraph(name);
    end
end