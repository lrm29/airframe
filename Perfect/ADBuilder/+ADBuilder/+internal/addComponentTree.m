function component = addComponentTree(architecture, activityStruct)
    % Get the list of path parts for this activity diagram
    [~, pathParts] = activityStruct.XMI_Database.getElementPath(activityStruct.xmi_idAttribute);

    % try to find each part in the component hierarchy, adding it if not
    % found and skipping the root.
    nextParent = architecture;
    for pathIdx = 2:numel(pathParts)
        componentName = pathParts(pathIdx);
        component = nextParent.getComponent(componentName);
        if isempty(component)
            component = addComponent(nextParent, componentName);
            % Clean up the diagram
            Simulink.BlockDiagram.arrangeSystem(nextParent.getQualifiedName);
        end
        nextParent = component.Architecture;
    end
end