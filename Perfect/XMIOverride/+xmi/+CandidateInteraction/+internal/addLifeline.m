function lifeline = addLifeline(parent, name)
    if isempty(name)
        name = xmi.CandidateAD.internal.nextName({parent.Model.Architecture.Components.Name}, 'Unnamed');
    end
    component = parent.Model.Architecture.addComponent(name);
    sequencediagram.internal.addLifeline(component.getQualifiedName, parent.Model.Name);
    lifeline = parent.Lifelines([parent.Lifelines.RelatedElements] == component);
end