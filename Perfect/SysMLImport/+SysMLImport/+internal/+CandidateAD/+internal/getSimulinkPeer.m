function simulinkHandle = getSimulinkPeer(activityElement)
    simulinkHandle = systemcomposer.utils.getSimulinkPeer(activityElement.p_TraitParent);
end