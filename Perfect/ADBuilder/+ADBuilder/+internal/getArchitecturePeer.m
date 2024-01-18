function architecturePeer = getArchitecturePeer(activityElement)
    architectureImpl = activityElement.p_TraitParent;
    architecturePeer = systemcomposer.internal.getWrapperForImpl(architectureImpl);
end