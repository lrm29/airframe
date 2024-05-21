classdef Graph < SysMLConnector.internal.XMIGraph.Node
    properties
        Profiles
        IDMap
    end

    properties (Hidden)
        NextElementID = 1
    end

    methods  (Access=protected)
        function graphObj = Graph(name, structure)
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
            end

            graphObj.IDMap(element.ID) = element;
        end

        function element = lookup(graphObj, elementID)
            element = [];
            try %#ok<TRYNC> do not slow this down with extra checks. If it does not work, return empty.
                element = graphObj.IDMap(elementID);
            end
        end

        function register(graphObj)
            graphObj.Graph = graphObj;
            graphObj.IDMap = dictionary;
        end
    end

    methods (Static)
        graphObj = getGraph(name);
    end
end