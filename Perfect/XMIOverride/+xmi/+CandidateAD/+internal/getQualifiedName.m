function qualifiedName = getQualifiedName(element)
    activityElement = element.ZCElement;
    archElement = xmi.CandidateAD.internal.getArchitecturePeer(activityElement);
    qualifiedName = archElement.getQualifiedName;
end