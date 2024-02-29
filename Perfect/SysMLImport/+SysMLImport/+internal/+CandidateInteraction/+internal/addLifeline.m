function lifeline = addLifeline(parent, name)
    if isempty(name)
        name = SysMLImport.internal.CandidateAD.internal.nextName({parent.Model.Architecture.Components.Name}, 'Unnamed');
    end
    % Escape slashes in name
    name = strrep(name, '/', '//');

    % Create a component
    component = parent.Model.Architecture.addComponent(name);

    % Add the lifeline
    sequencediagram.internal.addLifeline(component.getQualifiedName, parent.Model.Name);
    lifeline = parent.Lifelines([parent.Lifelines.RelatedElements] == component);
end