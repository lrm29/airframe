function qualifiedName = getQualifiedName(element)
    activityElement = element.ZCElement;
    archElement = SysMLImport.internal.CandidateAD.internal.getArchitecturePeer(activityElement);
    qualifiedName = archElement.getQualifiedName;
end