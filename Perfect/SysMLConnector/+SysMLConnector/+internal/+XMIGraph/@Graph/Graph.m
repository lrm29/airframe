classdef Graph < SysMLConnector.internal.XMIGraph.Node
    properties
        Profiles = -1
        XMIVisitor
        CachedWrappersByXMI
        CachedWrappersByMWID
    end

    methods  (Access=protected)
        function graphObj = Graph(name, structure)
            arguments
                name      = ''
                structure = ''
            end
            % If name and structure are empty, the XMI parsing failed and
            % this object is just a stub.

            graphObj@SysMLConnector.internal.XMIGraph.Node([], 1);

            graphObj.XMIVisitor = SysMLConnector.internal.XMIGraph.XMIVisitor(structure);
            graphObj.Struct = graphObj.XMIVisitor.lookup(1);

            [~, graphObj.Name] = fileparts(name);

            graphObj.CachedWrappersByXMI = dictionary;
            graphObj.CachedWrappersByMWID = dictionary;

            graphObj.CachedWrappersByXMI('__root__') = {graphObj};
            graphObj.CachedWrappersByMWID(1) = {graphObj};
        end
    end

    methods
        function profiles = get.Profiles(graphObj)
            if isequal(graphObj.Profiles, -1)
                % Time to initialize this property
                graphObj.Profiles = SysMLConnector.internal.XMIGraph.Node.empty;

                graphObj.Profiles = graphObj.getElementsByType('uml:Profile');
            end

            profiles = graphObj.Profiles;
        end

        function elements = getElementsByType(graphObj, xmiType)
            elements = [];
            try %#ok<TRYNC> do not slow this down with extra checks. If it does not work, return empty.
                if (nargin < 2) || isempty(xmiType)
                    % Return everything - Recommend to use this sparingly
                    % because this will trigger everything to be visited
                    % the first time it is called.
                    typeIDs = graphObj.XMIVisitor.ElementDict.keys;
                    elements = arrayfun(@(typeID) graphObj.lookupByMWID(typeID), typeIDs, UniformOutput=true);
                else
                    % Return the specified type
                    typeIDs = graphObj.XMIVisitor.getElementsByType(xmiType);
                    elements = arrayfun(@(typeID) graphObj.lookupByMWID(typeID), typeIDs, UniformOutput=true);
                end

                if ~isempty(elements)
                    elements = reshape(elements, 1, []);
                end
            end
        end

        function owner = getOwner(graphObj, nodeObj)
            owner = SysMLConnector.internal.XMIGraph.Node.empty;

            [~, parentID] = getParentByID(graphObj.XMIVisitor, nodeObj.MWID);
            if ~isempty(parentID)
                owner = graphObj.lookupByMWID(parentID);
            end
        end

        function element = addElement(graphObj, mwID, elementXMIID, elementStruct)
            if nargin < 4
                elementStruct = graphObj.XMIVisitor.lookup(mwID);
            end
            
            if isstruct(elementStruct)
                element = SysMLConnector.internal.XMIGraph.Node(graphObj, mwID);
                if nargin > 2
                    element.ID = elementXMIID;
                end
    
                element.Struct = elementStruct;
            else
                % The element is just a property value, not an object.
                element = elementStruct;
            end

            graphObj.CachedWrappersByMWID(mwID) = {element};
        end

        function elements = addElementsByXMI(graphObj, xmiID)
            elements = SysMLConnector.internal.XMIGraph.Node.empty;
            
            if ~isKey(graphObj.CachedWrappersByXMI, xmiID)
                [elementStructs, elementMWIDs] = lookupByXMI(graphObj.XMIVisitor, xmiID);

                if isempty(elementStructs)
                    % Cache the null result so this logic does not run
                    % again.
                    graphObj.CachedWrappersByXMI(xmiID) = {elements};

                    return;
                end

                % There were results found so lets update the cache.
                numElements = numel(elementStructs);

                elements = SysMLConnector.internal.XMIGraph.Node.empty(0, numElements);

                for elementIdx = 1:numElements
                    elementMWID = elementMWIDs(elementIdx);

                    if ~isKey(graphObj.CachedWrappersByMWID, elementMWID)
                        % Register the element
                        elements(elementIdx) = addElement(graphObj, elementMWID, xmiID, elementStructs{elementIdx});
                    else
                        % Tag the existing element with its XMI ID.
                        elements(elementIdx) = graphObj.CachedWrappersByMWID{elementMWID};
                        elements(elementIdx).ID = xmiID;
                    end

                    % Mark the duplicate fields as initialized
                    elements(elementIdx).Duplicates = SysMLConnector.internal.XMIGraph.Node.empty;
                    elements(elementIdx).DuplicateOf = SysMLConnector.internal.XMIGraph.Node.empty;

                    % Link the duplicates together
                    if elementIdx > 1
                        % Tag the duplicates
                        elements(1).Duplicates(elementIdx-1) = elements(elementIdx);
                        elements(elementIdx).DuplicateOf = elements(1);
                    elseif numElements > 1
                        % Allocate space for the duplicates
                        elements(1).Duplicates = SysMLConnector.internal.XMIGraph.Node.empty(0, numel(elementStructs) - 1);
                    end
                end
            end
        end

        function element = lookupByMWID(graphObj, mwID)
            if isKey(graphObj.CachedWrappersByMWID, mwID)
                element = [graphObj.CachedWrappersByMWID{mwID}];
                return;
            else
                element = addElement(graphObj, mwID);
            end

            graphObj.initializeElement(element);
        end

        function elements = lookup(graphObj, xmiID)
            if isKey(graphObj.CachedWrappersByXMI, xmiID)
                elements = [graphObj.CachedWrappersByXMI{xmiID}];
                return;
            else
                elements = addElementsByXMI(graphObj, xmiID);
            end

            arrayfun(@(element) graphObj.initializeElement(element), elements);
        end

        function initializeElement(~, element)
            if isa(element, 'SysMLConnector.internal.XMIGraph.Node')
                element.initializeXMI;
                element.initializeProperties;
            end
        end
    end

    methods (Static)
        graphObj = getGraph(name);
    end
end