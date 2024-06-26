function endPoint = getEndPoint(candidateInteraction,event)
arguments
    candidateInteraction SysMLConnector.internal.CandidateInteraction.Interaction
    event 
end
if isempty(event)
    endPoint = candidateInteraction;
else
    endPoint = candidateInteraction.LifeLineMap( ...
        SysMLConnector.internal.utils.getExtID(event.covered.at(1)));
end
end