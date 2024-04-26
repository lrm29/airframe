function qualifiedName = getQualifiedName(element)
    activityElement = element.ZCElement;
    archElement = SysMLConnector.internal.CandidateAD.internal.getArchitecturePeer(activityElement);
    qualifiedName = archElement.getQualifiedName;
end