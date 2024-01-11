function architecturePeer = getArchitecturePeer(activityElement)
    if isa(activityElement, 'systemcomposer.activitydiagram.model.Activity')
        architecturePeer = activityElement.p_Architecture;
    elseif isa(activityElement, 'systemcomposer.activitydiagram.model.Pin')
        architecturePeer = activityElement.p_ComponentPort;
    elseif isa(activityElement, 'systemcomposer.activitydiagram.model.Parameter')
        architecturePeer = activityElement.p_ArchitecturePort;
    elseif isa(activityElement, 'systemcomposer.activitydiagram.model.ActivityNode')
        architecturePeer = activityElement.p_Component;
    elseif isa(activityElement, 'systemcomposer.activitydiagram.model.Flow')
        architecturePeer = activityElement.p_BinaryConnector;
    else
        error('ADBuilder:internal:getArchitecturePeer:UnhandledType', 'Unable to find architecture element for type ''%s'' with value:\n\n%s\n\n\n', class(activityElement), formattedDisplayText(activityElement));
    end

    architecturePeer = systemcomposer.internal.getWrapperForImpl(architecturePeer);
end