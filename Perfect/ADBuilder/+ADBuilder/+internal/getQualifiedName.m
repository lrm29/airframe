function qualifiedName = getQualifiedName(element)
    activityElement = element.ZCElement;
    archElement = ADBuilder.internal.getArchitecturePeer(activityElement);
    qualifiedName = archElement.getQualifiedName;
end