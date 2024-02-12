function setName(activityElement, newName)
    % Set the name of a System Composer activity element by setting the
    % name on the underlying architecture element.
    archElement = xmi.CandidateAD.internal.getArchitecturePeer(activityElement);
    
    % Avoid dirtying the model if not necessary
    if ~strcmp(archElement.Name, newName)
        archElement.Name = newName;
    end
end