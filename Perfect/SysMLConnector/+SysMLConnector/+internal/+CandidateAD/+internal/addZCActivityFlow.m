function flow = addZCActivityFlow(source, destination, NameValueArgs)
    arguments
        source                    systemcomposer.activitydiagram.model.ActivityNode
        destination               systemcomposer.activitydiagram.model.ActivityNode
        NameValueArgs.Guard = ''
    end

    [sourcePortHandle,      sourceParentPath]      = getPortHandle(source, false);
    [destinationPortHandle, destinationParentPath] = getPortHandle(destination, true);
    assert(strcmp(sourceParentPath, destinationParentPath), 'SysMLConnector:internal:CandidateAD:internal:addZCActivityFlow:AmbiguousFlowPath', ...
        'The parent of the source and destination are different. Please provide a valid source/destination pairing.\nSource Parent: %s\nDestination Parent: %s\n', sourceParentPath, destinationParentPath);
    
    parentPath = sourceParentPath;

    % Get expression and make connection
    sourceExpression = systemcomposer.internal.getPortExprFromHandle(sourcePortHandle);
    destinationExpression = systemcomposer.internal.getPortExprFromHandle(destinationPortHandle);

    topModel = bdroot(parentPath);

    try
        add_line(parentPath, sourceExpression, destinationExpression, 'AUTOROUTING', 'on');
    catch ME
        error('SysMLConnector:internal:CandidateAD:internal:addZCActivityFlow:InvalidConnection', 'Error connecting activities.\n  Parent Path: %s\n  Source Expression: %s\n  Destination Expression: %s\n Error Code: %s (%i)\n', parentPath, sourceExpression, destinationExpression, ME.identifier, ME.stack(1).line);
    end
    
    % Get flow to return. Add in retry for race condition.
    errorCount = 0;
    conn = [];
    while isempty(conn)
        % Flushing the modeling queue.
        systemcomposer.internal.arch.internal.processBatchedPluginEvents(topModel);

        try
            compPort = systemcomposer.utils.getArchitecturePeer(sourcePortHandle);
            conn = compPort.getConnectors;
            flow = conn.getTrait(systemcomposer.activitydiagram.model.Flow.StaticMetaClass);
        catch ME
            errorCount = errorCount + 1;

            % Wait to see if the queue just needs more time.
            pause(0.250);
        end

        if errorCount > 2
            error('SysMLConnector:internal:CandidateAD:internal:addZCActivityFlow:MissingFlow', 'Missing activity flow.\n  Parent Path: %s\n  Source Expression: %s\n  Destination Expression: %s\n Error Code: %s (%i)\n', parentPath, sourceExpression, destinationExpression, ME.identifier, ME.stack(1).line);
        end
    end

    if ~isempty(NameValueArgs.Guard)
        setGuard(flow, NameValueArgs.Guard);
    end
end

% Internal helper to get port handle from activity object.
function [portHandle, parentPath] = getPortHandle(activityObject, isInput)
    implObject = activityObject.p_TraitParent;
    
    switch class(implObject)
        case 'systemcomposer.architecture.model.design.Component'
            parentPath = implObject.p_Parent.getQualifiedName;
            safeName = strrep(activityObject.Name, '/', '//');
            archPortHandle = systemcomposer.activitydiagram.internal.commands.addPort(...
                [parentPath '/' safeName], isInput, 'Control');
            archPort = systemcomposer.utils.getArchitecturePeer(archPortHandle);
            compPort = archPort.getParentComponentPort;
            portHandle = systemcomposer.utils.getSimulinkPeer(compPort);

            return;
        case 'systemcomposer.architecture.model.design.Architecture'
            parentPath = implObject.getQualifiedName;
            safeName = strrep(activityObject.Name, '/', '//');
            portHandle = systemcomposer.activitydiagram.internal.commands.addPort(...
                [parentPath '/' safeName], isInput, 'Control'); 

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
            error('SysMLConnector:internal:CandidateAD:internal:addZCActivityFlow:UnexpectedInputType', 'addZCActivityFlow received an unexpected input type of ''%s''.\n\n%s\n', class(activityObject), formattedDisplayText(activityObject));
    end

    % <ProductSupportPackage><Protect/></ProductSupportPackage>
end