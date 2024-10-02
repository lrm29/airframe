function endPoint = getEndPoint(candidateInteraction, messageOrEvent, eventName)    
    if nargin > 2
        % Message was passed in
        event = messageOrEvent.(eventName);
    else
        % Event was passed in
        event = messageOrEvent;
    end

    if isempty(event) 
        endPoint = candidateInteraction;
    else
        if isempty(event.covered.at(1))
            eventID = SysMLConnector.internal.utils.getExtID(event);
            g = SysMLConnector.internal.XMIGraph.Graph.getGraph(event.rootModel.uri);
            lifelineID = g.lookup(eventID).getProperty('coveredAttribute');
        else
            lifelineID = SysMLConnector.internal.utils.getExtID(event.covered.at(1));
        end
        endPoint = candidateInteraction.getLifeline(lifelineID, event);
    end
end