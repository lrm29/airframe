function [candidateAD, notImported] = buildCandidateAD(adStruct, candidateAD)
    notImported = [];

    if ~isscalar(adStruct)
        candidateAD = arrayfun(@xmi.CandidateAD.buildCandidateAD, adStruct);
        return
    end

    if iscell(adStruct)
        adStruct = adStruct{1};
    end

    if (nargin < 2) || isempty(candidateAD)
        candidateAD = xmi.CandidateAD.Model(Name=adStruct.name, ExternalID=xmi.utils.getExtID(adStruct));
    end

    if adStruct.node.size < 1
        % Blank diagram.
        return;
    end

    mdlIdx = xmi.CandidateAD.getModelIndex;

    for nodeIdx = 1:adStruct.node.size
        nodeStruct = adStruct.node.at(nodeIdx);

        nodeName = '';
        behavior = false;
        structuredActivity = false;

        if ~isempty(nodeStruct.name)
            nodeName = nodeStruct.name;
        elseif isprop(nodeStruct, 'body') && ~isempty(nodeStruct.body)
            nodeName = nodeStruct.body.at(1);
        end

        nodeID = xmi.utils.getExtID(nodeStruct);
        nodeType = class(nodeStruct);

        switch nodeType
            case 'umlmm.InitialNode'
                node = candidateAD.addNode(nodeName, 'Initial', nodeID);
            case 'umlmm.ActivityFinalNode'
                node = candidateAD.addNode(nodeName, 'ActivityFinal', nodeID);
            case {'umlmm.MergeNode', 'umlmm.DecisionNode'}
                node = candidateAD.addNode(nodeName, 'MergeDecision', nodeID);
            case {'umlmm.JoinNode', 'umlmm.ForkNode'}
                node = candidateAD.addNode(nodeName, 'JoinFork', nodeID);
            case 'umlmm.ActivityParameterNode'
                % This is actually an input or output pin for the activity.
                parameter = nodeStruct.parameter;
                if ~isempty(parameter.direction)
                    switch parameter.direction.toString
                        case 'in'
                            direction = systemcomposer.activitydiagram.model.PortDirection.INPUT;
                        case 'out'
                            direction = systemcomposer.activitydiagram.model.PortDirection.OUTPUT;
                        otherwise
                            error('xmi:CandidateAD:buildCandidateAD:UnhandledParameterDirection', 'Unhandled parameter direction ''%s'' detected.\n\n%s\n\n', parameter.direction, formattedDisplayText(parameter));
                    end
                else
                    direction = systemcomposer.activitydiagram.model.PortDirection.INPUT;
                end

                pin = addParameter(candidateAD, nodeName, ...
                             systemcomposer.activitydiagram.model.TokenType.OBJECT, ...
                             direction, nodeID); %#ok<NASGU>

                continue;
            otherwise % uml:Activity or uml:CallBehaviorAction
                subProp =  [];
                subName = '';

                if isa(nodeStruct, 'umlmm.ReadStructuralFeatureAction')
                    if ~isempty(nodeStruct.structuralFeature)
                        subProp = nodeStruct.structuralFeature;
                    end
                elseif isa(nodeStruct, 'umlmm.CallOperationAction')
                    if ~isempty(nodeStruct.operation)
                        subProp = nodeStruct.operation;
                    end
                elseif isa(nodeStruct, 'umlmm.SendSignalAction')
                    if ~isempty(nodeStruct.signal)
                        subProp = nodeStruct.signal;
                    end
                elseif isa(nodeStruct, 'umlmm.CallBehaviorAction')
                    if ~isempty(nodeStruct.behavior)
                        subProp = nodeStruct.behavior;
                        behavior = true;
                    end
                elseif isa(nodeStruct, 'umlmm.StructuredActivityNode')
                    % Build the child structure
                    behavior = true;
                    structuredActivity = true;
                end

                if startsWith(nodeType, 'umlmm.')
                    headerString = extractAfter(nodeType, 'umlmm.');
                else
                    headerString = nodeType;
                end
                header = sprintf('<<%s>>', headerString);

                if ~isempty(nodeName) || ~isempty(subName)
                    header = sprintf('%s\n', header);
                end

                if ~isempty(subProp) && ~isempty(subProp.name)
                    subName = sprintf(' : %s', subProp.name);
                end

                nodeName = sprintf('%s%s%s', header, nodeName, subName);
                node = candidateAD.addNode(nodeName, 'Activity', nodeID);
        end

        % Add object pins
        for fieldName = {'object', 'result', 'target', 'argument', 'inputValue', 'outputValue'}
            if isprop(nodeStruct, char(fieldName))
                xmi.CandidateAD.internal.createPins(node, nodeStruct.(char(fieldName)));
            end
        end

        % Add sub-activites
        if behavior
            if structuredActivity
                node.ActionBehavior = systemcomposer.activitydiagram.model.BehaviorLanguage.ACTIVITY;
                % build the child architecture in place (model ref in activities not supported yet).
                xmi.CandidateAD.buildCandidateAD(nodeStruct, node);
            elseif isa(subProp, 'umlmm.Activity')
                node.ActionBehavior = systemcomposer.activitydiagram.model.BehaviorLanguage.ACTIVITY;
                node.ReferenceID = xmi.utils.getExtID(subProp);
                
                % Build the reference activity if it has not yet been
                % built.
                refNode = [];

                mdlDB = mdlIdx.getElement(subProp.name);
                if ~isempty(mdlDB)
                    refNode = mdlDB.getElement(node.ReferenceID);
                end

                if isempty(refNode)
                    % only build reference activity once then save the
                    % reference by ID in the current model lookup database.
                    refNode = xmi.CandidateAD.buildCandidateAD(subProp);
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

    if isempty(adStruct.edge)
        % No connections.
        return;
    end

    for edgeIdx = 1:adStruct.edge.size
        try
            edgeStruct = adStruct.edge.at(edgeIdx);
    
            guard = '';
            if ~isempty(edgeStruct.guard) 
                if isprop(edgeStruct.guard, 'body') && ~isempty(edgeStruct.guard.body)
                    guard = edgeStruct.guard.body.at(1);
                elseif isa(edgeStruct.guard, 'umlmm.LiteralString')
                    if ~isempty(edgeStruct.guard.value)
                        guard = edgeStruct.guard.value;
                    else
                        guard = '';
                    end
                elseif isa(edgeStruct.guard, 'umlmm.LiteralBoolean')
                    if ~isempty(edgeStruct.guard.value)
                        guard = edgeStruct.guard.value;
                    else
                        guard = 'false';
                    end
                end
            end
    
            assert(~isempty(edgeStruct.source), 'Missing Source');
            assert(~isempty(edgeStruct.target), 'Missing Target');

            sourceID      = xmi.utils.getExtID(edgeStruct.source);
            destinationID = xmi.utils.getExtID(edgeStruct.target);
    
            source = candidateAD.Model.lookup(sourceID);
            destination = candidateAD.Model.lookup(destinationID);
    
            switch class(edgeStruct)
                case 'umlmm.ControlFlow'
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
                 case 'umlmm.ObjectFlow'
                    % Object pins exist and should have been added during node
                    % construction.
                    sourcePin = source;
                    destinationPin = destination;
                otherwise
                    fprintf('Unrecognized UML edge type of ''%s'' in activity ''%s''.\n\n', class(edgeStruct), adStruct.name.toString);
                    continue;
            end

            connect(sourcePin, destinationPin, guard, xmi.utils.getExtID(edgeStruct));

        catch ME
            notImp.Type = xmi.CandidateAD.internal.getClassName(edgeStruct);
            notImp.Element = xmi.UMLVisitor.getFullPath(edgeStruct);
            notImp.Reason = ME.message;
            scName = xmi.UMLVisitor.getSysMLStereotype(edgeStruct);
            notImp.Stereotype = scName;

            notImported = [notImported notImp]; %#ok<AGROW>
        end
    end
end