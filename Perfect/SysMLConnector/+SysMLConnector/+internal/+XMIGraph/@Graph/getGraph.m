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

            try
                structure = readstruct(name);
            catch topME
                % If readstruct fails, try using a back-up parser that is
                % slower.
                try
                    structure = SysMLConnector.internal.utils.auxParseXML(name);
                catch
                    rethrow(topME);
                end
            end

            try
                graphDB(name) = SysMLConnector.internal.XMIGraph.Graph(name, structure);
            catch
                graphDB(name) = SysMLConnector.internal.XMIGraph.Graph;
            end
        end

        graphObj = graphDB(name);
end