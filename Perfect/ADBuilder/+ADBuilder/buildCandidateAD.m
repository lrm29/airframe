function candidateAD = buildCandidateAD(adStruct, candidateAD)
    if ~isscalar(adStruct)
        candidateAD = arrayfun(@ADBuilder.buildCandidateAD, adStruct);
        return
    end

    if iscell(adStruct)
        adStruct = adStruct{1};
    end

    if (nargin < 2) || isempty(candidateAD)
        candidateAD = CandidateAD.Model(Name=adStruct.nameAttribute, ExternalID=adStruct.xmi_idAttribute);
    end

    if ~isfield(adStruct, 'node')
        % Blank diagram.
        return;
    end

    mdlIdx = CandidateAD.getModelIndex;

    for nodeStruct = adStruct.node
        nodeName = '';
        behavior = false;
        structuredActivity = false;

        if isfield(nodeStruct, 'nameAttribute') && ~ismissing(nodeStruct.nameAttribute)
            nodeName = nodeStruct.nameAttribute;
        elseif isfield(nodeStruct, 'body') && ~ismissing(nodeStruct.body)
            nodeName = char(nodeStruct.body);
        end

        nodeID = nodeStruct.xmi_idAttribute;

        switch char(nodeStruct.xmi_typeAttribute)
            case 'uml:InitialNode'
                node = candidateAD.addNode(nodeName, 'Initial', nodeID);
            case 'uml:ActivityFinalNode'
                node = candidateAD.addNode(nodeName, 'ActivityFinal', nodeID);
            case {'uml:MergeNode', 'uml:DecisionNode'}
                node = candidateAD.addNode(nodeName, 'MergeDecision', nodeID);
            case {'uml:JoinNode', 'uml:ForkNode'}
                node = candidateAD.addNode(nodeName, 'JoinFork', nodeID);
            case 'uml:ActivityParameterNode'
                % This is actually an input or output pin for the activity.
                parameter = lookup(adStruct.XMI_Database, nodeStruct.parameterAttribute);
                if isfield(parameter, 'directionAttribute')
                    if ismissing(parameter.directionAttribute)
                        % Assume input by default.
                        direction = 'in';
                    else
                        switch char(parameter.directionAttribute)
                            case 'in'
                                direction = systemcomposer.activitydiagram.model.PortDirection.INPUT;
                            case 'out'
                                direction = systemcomposer.activitydiagram.model.PortDirection.OUTPUT;
                            otherwise
                                error('ADBuilder:buildCandidateAD:UnhandledParameterDirection', 'Unhandled parameter direction ''%s'' detected.\n\n%s\n\n', parameter.directionAttribute, formattedDisplayText(parameter));
                        end
                    end
                else
                    direction = systemcomposer.activitydiagram.model.PortDirection.INPUT;
                end

                pin = addParameter(candidateAD, nodeName, ...
                             systemcomposer.activitydiagram.model.TokenType.OBJECT, ...
                             direction, nodeStruct.xmi_idAttribute); %#ok<NASGU>

                continue;
            otherwise % uml:Activity or uml:CallBehaviorAction
                subProp =  [];
                subName = '';

                if strcmp(nodeStruct.xmi_typeAttribute, 'uml:ReadStructuralFeatureAction')
                    if isfield(nodeStruct, 'structuralFeatureAttribute') && ~ismissing(nodeStruct.structuralFeatureAttribute)
                        subProp = lookup(adStruct.XMI_Database, nodeStruct.structuralFeatureAttribute);
                    end
                elseif strcmp(nodeStruct.xmi_typeAttribute, 'uml:CallOperationAction')
                    if isfield(nodeStruct, 'operationAttribute') && ~ismissing(nodeStruct.operationAttribute)
                        subProp = lookup(adStruct.XMI_Database, nodeStruct.operationAttribute);
                    end
                elseif strcmp(nodeStruct.xmi_typeAttribute, 'uml:SendSignalAction')
                    if isfield(nodeStruct, 'signalAttribute') && ~ismissing(nodeStruct.signalAttribute)
                        subProp = lookup(adStruct.XMI_Database, nodeStruct.signalAttribute);
                    end
                elseif strcmp(nodeStruct.xmi_typeAttribute, 'uml:CallBehaviorAction')
                    if isfield(nodeStruct, 'behaviorAttribute') && ~ismissing(nodeStruct.behaviorAttribute)
                        subProp = lookup(adStruct.XMI_Database, nodeStruct.behaviorAttribute);
                        behavior = true;
                    end
                elseif strcmp(nodeStruct.xmi_typeAttribute, 'uml:StructuredActivityNode')
                    % Build the child structure
                    behavior = true;
                    structuredActivity = true;
                end

                if startsWith(nodeStruct.xmi_typeAttribute, 'uml:')
                    headerString = extractAfter(nodeStruct.xmi_typeAttribute, 'uml:');
                else
                    headerString = nodeStruct.xmi_typeAttribute;
                end
                header = sprintf('<<%s>>', headerString);

                if ~isempty(nodeName) || ~isempty(subName)
                    header = sprintf('%s\n', header);
                end

                if ~isempty(subProp) && ~ismissing(subProp) && isfield(subProp, 'nameAttribute') && ~ismissing(subProp.nameAttribute)
                    subName = sprintf(' : %s', subProp.nameAttribute);
                end

                nodeName = sprintf('%s%s%s', header, nodeName, subName);
                node = candidateAD.addNode(nodeName, 'Activity', nodeID);
        end

        % Add object pins
        for fieldName = {'object', 'result', 'target', 'argument', 'inputValue', 'outputValue'}
            if isfield(nodeStruct, char(fieldName))
                ADBuilder.internal.createPins(node, nodeStruct.(char(fieldName)));
            end
        end

        % Add sub-activites
        if behavior
            if structuredActivity
                node.ActionBehavior = systemcomposer.activitydiagram.model.BehaviorLanguage.ACTIVITY;
                % Propogate the imported XMI database then build the child
                % architecture in place.
                nodeStruct.XMI_Database = adStruct.XMI_Database;
                ADBuilder.buildCandidateAD(nodeStruct, node);
            elseif isfield(subProp, 'xmi_typeAttribute') && strcmp(subProp.xmi_typeAttribute, 'uml:Activity')
                node.ActionBehavior = systemcomposer.activitydiagram.model.BehaviorLanguage.ACTIVITY;
                node.ReferenceID = subProp.xmi_idAttribute;
                
                % Build the reference activity if it has not yet been
                % built.
                refNode = [];

                mdlDB = mdlIdx.getElement(subProp.nameAttribute);
                if ~isempty(mdlDB)
                    refNode = mdlDB.getElement(subProp.xmi_idAttribute);
                end

                if isempty(refNode)
                    % only build reference activity once then save the
                    % reference by ID in the current model lookup database.
                    refNode = ADBuilder.buildCandidateAD(subProp);
                end

                % If the reference model has not been registered with
                % the model already then register it.
                model = candidateAD.Model;
                if isempty(model.lookup(refNode.ExternalID))
                    model.register(refNode);
                end
            end
        end
    end

    if ~isfield(adStruct, 'edge') || all(ismissing(adStruct.edge))
        % No connections.
        return;
    end

    for edgeStruct = adStruct.edge
        guard = '';
        if isfield(edgeStruct, 'guard') && ~ismissing(edgeStruct.guard) 
            if isfield(edgeStruct.guard, 'body') && ~ismissing(edgeStruct.guard.body)
                guard = edgeStruct.guard.body;
            elseif strcmp(edgeStruct.guard.xmi_typeAttribute, 'uml:LiteralString')
                if isfield (edgeStruct.guard, 'valueAttribute') && ~ismissing(edgeStruct.guard.valueAttribute)
                    guard = edgeStruct.guard.valueAttribute;
                else
                    guard = '';
                end
            elseif strcmp(edgeStruct.guard.xmi_typeAttribute, 'uml:LiteralBoolean')
                if isfield (edgeStruct.guard, 'valueAttribute') && ~ismissing(edgeStruct.guard.valueAttribute)
                    guard = edgeStruct.guard.valueAttribute;
                else
                    guard = 'false';
                end
            end
        end

        source = candidateAD.Model.lookup(edgeStruct.sourceAttribute);
        destination = candidateAD.Model.lookup(edgeStruct.targetAttribute);

        switch char(edgeStruct.xmi_typeAttribute)
            case 'uml:ControlFlow'
                % Add pins on source and destination 
                % 
                % Note: Control pins are "virtual" and do not really exist
                % in UML activity diagrams. This just gives us somewhere to
                % semantically start and end the connector.

                sourcePin = addPin(source, '', ...
                                   systemcomposer.activitydiagram.model.TokenType.CONTROL, ...
                                   systemcomposer.activitydiagram.model.PortDirection.OUTPUT);
        
                destinationPin = addPin(destination, '', ...
                                        systemcomposer.activitydiagram.model.TokenType.CONTROL, ...
                                        systemcomposer.activitydiagram.model.PortDirection.INPUT);
             case 'uml:ObjectFlow'
                % Object pins exist and should have been added during node
                % construction.
                sourcePin = source;
                destinationPin = destination;
            otherwise
                fprintf('Unrecognized UML edge type of ''%s'' in activity ''%s''.\n\n', char(edgeStruct.xmi_typeAttribute), char(adStruct.nameAttribute));
                continue;
        end

        connect(sourcePin, destinationPin, guard, edgeStruct.xmi_idAttribute);
    end
end