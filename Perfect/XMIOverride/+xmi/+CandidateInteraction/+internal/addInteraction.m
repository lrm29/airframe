function interaction = addInteraction(zcMdl, interactionName)
    sequencediagram.internal.createSequenceDiagram(zcMdl.Name, interactionName);
    sequencediagram.internal.open(zcMdl.Name, interactionName);
    interaction = getInteraction(zcMdl, interactionName);
end