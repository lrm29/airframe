function graphObj = getGraph(name, options)
        arguments
            name
            options.Refresh (1,1) logical = false
        end

        persistent graphDB

        if isempty(graphDB)
            graphDB = dictionary;
        end

        if options.Refresh || isequal(graphDB.numEntries, 0) || ~isKey(graphDB, name)
            if options.Refresh && ~isequal(graphDB.numEntries, 0) && isKey(graphDB, name)
                delete(graphDB(name));
            end

            structure = readstruct(name);

            try
                graphDB(name) = SysMLConnector.internal.XMIGraph.Graph(name, structure);
            catch
                graphDB(name) = SysMLConnector.internal.XMIGraph.Graph.empty;
            end
        end

        graphObj = graphDB(name);
end