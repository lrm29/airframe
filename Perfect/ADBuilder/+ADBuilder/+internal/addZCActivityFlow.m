function flow = addZCActivityFlow(source, destination, NameValueArgs)
    arguments
        source                    systemcomposer.internal.Trait
        destination               systemcomposer.internal.Trait
        NameValueArgs.Guard = ''
    end

    [sourcePortHandle,      sourceParentPath]      = getPortHandle(source, false);
    [destinationPortHandle, destinationParentPath] = getPortHandle(destination, true);
    assert(strcmp(sourceParentPath, destinationParentPath), 'ADBuilder:internal:addZCActivityFlow:AmbiguousFlowPath', ...
        'The parent of the source and destination are different. Please provide a valid source/destination pairing.\nSource Parent: %s\nDestination Parent: %s\n', sourceParentPath, destinationParentPath);
    
    parentPath = sourceParentPath;

    % Get expression and make connection
    sourceExpression = systemcomposer.internal.getPortExprFromHandle(sourcePortHandle);
    destinationExpression = systemcomposer.internal.getPortExprFromHandle(destinationPortHandle);
    
    editor = systemcomposer.activitydiagram.internal.getEditor();
    editor.createMCommand('activitydiagram:AddFlow', 'Add Flow to Activity', ...
        @addLine, {parentPath, sourceExpression, destinationExpression});
    
    % Get flow to return
    compPort = systemcomposer.utils.getArchitecturePeer(sourcePortHandle);
    conn = compPort.getConnectors;
    flow = conn.getTrait(systemcomposer.activitydiagram.model.Flow.StaticMetaClass);

    if ~isempty(NameValueArgs.Guard)
        setGuard(flow, NameValueArgs.Guard);
    end
end

% Internal helper to call via callback
function addLine(parentPath, sourceExpression, destinationExpression)
    topModel = bdroot(parentPath);

    try
        add_line(parentPath, sourceExpression, destinationExpression, 'AUTOROUTING', 'on');
        systemcomposer.internal.arch.internal.processBatchedPluginEvents(topModel);
    catch ME
        fprintf('Parent Path: %s\nSource Expression: %s\nDestination Expression: %s\n\n', parentPath, sourceExpression, destinationExpression);
        getReport(ME);
    end
end

% Internal helper to get port handle from activity object.
function [portHandle, parentPath] = getPortHandle(activityObject, isInput)
    implObject = activityObject.p_TraitParent;
    
    switch class(implObject)
        case 'systemcomposer.architecture.model.design.Component'
            parentPath = implObject.p_Parent.getQualifiedName;
            archPortHandle = systemcomposer.activitydiagram.internal.commands.addPort(...
                [parentPath '/' activityObject.Name], isInput, 'Control');
            archPort = systemcomposer.utils.getArchitecturePeer(archPortHandle);
            compPort = archPort.getParentComponentPort;
            portHandle = systemcomposer.utils.getSimulinkPeer(compPort);

            return;
        case 'systemcomposer.architecture.model.design.Architecture'
            parentPath = implObject.getQualifiedName;
            portHandle = systemcomposer.activitydiagram.internal.commands.addPort(...
                [parentPath '/' activityObject.Name], isInput, 'Control'); 

            return;
        case 'systemcomposer.architecture.model.design.ArchitecturePort'
            parentPath = implObject.p_Architecture.getQualifiedName;
            portHandle = systemcomposer.utils.getSimulinkPeer(implObject);

            return;
        case 'systemcomposer.architecture.model.design.ComponentPort'
            parentPath = implObject.p_Component.p_Parent.getQualifiedName;
            portHandle = systemcomposer.utils.getSimulinkPeer(implObject);

            return;
        otherwise
            error('ADBuilder:internal:addZCActivityFlow:UnexpectedInputType', 'addZCActivityFlow received an unexpected input type of ''%s''.\n\n%s\n', class(activityObject), formattedDisplayText(activityObject));
    end
end