function [candidateAD, notImported] = buildCandidateAD(adStruct, candidateAD)
    notImported = [];

    if ~isscalar(adStruct)
        candidateAD = arrayfun(@SysMLImport.internal.CandidateAD.buildCandidateAD, adStruct);
        return
    end

    if iscell(adStruct)
        adStruct = adStruct{1};
    end

    if (nargin < 2) || isempty(candidateAD)
        candidateAD = SysMLImport.internal.CandidateAD.Model(Name=adStruct.name, ExternalID=SysMLImport.internal.utils.getExtID(adStruct));
    end

    if adStruct.node.size < 1
        % Blank diagram.
        return;
    end

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

        nodeID = SysMLImport.internal.utils.getExtID(nodeStruct);
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
                if isempty(parameter)
                    direction = systemcomposer.activitydiagram.model.PortDirection.INPUT;

                    warning('xmi:CandidateAD:buildCandidateAD:UnspecifiedParameter', 'Parameter node ''%s'' in activity diagram ''%s'' has an unspecified parameter attribute. Please review the imported diagram for correctness.', nodeName, adStruct.name);

                    if nodeStruct.incoming.size > 0 && isequal(nodeStruct.outgoing.size, 0)
                        direction = systemcomposer.activitydiagram.model.PortDirection.OUTPUT;
                    elseif (nodeStruct.incoming.size > 0) && (nodeStruct.outgoing.size > 0)
                        % Bidirectional so add two pins
                        pin = addParameter(candidateAD, [nodeName '_in'], ...
                             systemcomposer.activitydiagram.model.TokenType.OBJECT, ...
                             systemcomposer.activitydiagram.model.PortDirection.INPUT, ...
                             [nodeID '_in']); %#ok<NASGU>
                        pin = addParameter(candidateAD, [nodeName '_out'], ...
                             systemcomposer.activitydiagram.model.TokenType.OBJECT, ...
                             systemcomposer.activitydiagram.model.PortDirection.OUTPUT, ...
                             [nodeID '_out']); %#ok<NASGU>
                        continue;
                    end
                elseif ~isempty(parameter.direction)
                    switch parameter.direction.toString
                        case 'in'
                            direction = systemcomposer.activitydiagram.model.PortDirection.INPUT;
                        case 'out'
                            direction = systemcomposer.activitydiagram.model.PortDirection.OUTPUT;
                        case 'return'
                            warning('xmi:CandidateAD:buildCandidateAD:ReturnParameter', 'Parameter node ''%s'' in activity diagram ''%s'' has a direction of return and has been converted to an output. Please review the imported diagram for correctness.', nodeName, adStruct.name);
                            direction = systemcomposer.activitydiagram.model.PortDirection.OUTPUT;
                        otherwise
                            error('xmi:CandidateAD:buildCandidateAD:UnhandledParameterDirection', 'Unhandled parameter direction ''%s'' detected.\n\n%s\n\n', parameter.direction.toString, formattedDisplayText(parameter));
                    end
                else
                    direction = systemcomposer.activitydiagram.model.PortDirection.INPUT;
                end

                pin = addParameter(candidateAD, nodeName, ...
                             systemcomposer.activitydiagram.model.TokenType.OBJECT, ...
                             direction, nodeID); 

                if ~isempty(parameter)
                    pin.ReferenceID = SysMLImport.internal.utils.getExtID(parameter);
                end

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
                SysMLImport.internal.CandidateAD.internal.createPins(node, nodeStruct.(char(fieldName)), CallBehaviorAction=(behavior & ~structuredActivity));
            end
        end

        % Add sub-activities
        if behavior
            if structuredActivity
                node.ActionBehavior = systemcomposer.activitydiagram.model.BehaviorLanguage.ACTIVITY;
                % build the child architecture in place (model ref in activities not supported yet).
                [~, notImp] = SysMLImport.internal.CandidateAD.buildCandidateAD(nodeStruct, node);
                notImported = [notImported notImp]; %#ok<AGROW>
            elseif isa(subProp, 'umlmm.Activity')
                node.ActionBehavior = systemcomposer.activitydiagram.model.BehaviorLanguage.ACTIVITY;
                node.ReferenceID = SysMLImport.internal.utils.getExtID(subProp);
            end
        end
    end

    if ~isprop(adStruct, 'edge') || isempty(adStruct.edge)
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

            sourceID      = SysMLImport.internal.utils.getExtID(edgeStruct.source);
            destinationID = SysMLImport.internal.utils.getExtID(edgeStruct.target);
    
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

            connect(sourcePin, destinationPin, guard, SysMLImport.internal.utils.getExtID(edgeStruct));

        catch ME
            notImp.Type = SysMLImport.internal.CandidateAD.internal.getClassName(edgeStruct);
            notImp.Element = SysMLImport.internal.UMLVisitor.getFullPath(edgeStruct);
            notImp.Reason = ME.message;
            scName = SysMLImport.internal.UMLVisitor.getSysMLStereotype(edgeStruct);
            notImp.Stereotype = scName;

            notImported = [notImported notImp]; %#ok<AGROW>
        end
    end
end