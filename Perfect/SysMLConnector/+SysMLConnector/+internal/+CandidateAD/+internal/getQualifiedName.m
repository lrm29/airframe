function qualifiedName = getQualifiedName(element)
    activityElement = element.BuiltElement;
    archElement = SysMLConnector.internal.CandidateAD.internal.getArchitecturePeer(activityElement);
    qualifiedName = archElement.getQualifiedName;
end