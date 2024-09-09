function node = getNode(umlElement)
    node = SysMLConnector.internal.XMIGraph.Node.empty;
    
    if ~isempty(umlElement)
        nodeID = SysMLConnector.internal.utils.getExtID(umlElement);

        fileName = umlElement.modelM3I.uri;
        xmiGraph = SysMLConnector.internal.XMIGraph.Graph.getGraph(fileName);

        foundNode = xmiGraph.lookup(nodeID);

        if ~isempty(foundNode)
            % In the case of duplicates, only return the first
            node = foundNode(1);
        end
    end  

    % <ProductSupportPackage><Protect/></ProductSupportPackage>
end