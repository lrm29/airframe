classdef Pin < SysMLConnector.internal.CandidateAD.Element
    properties
        TokenType systemcomposer.activitydiagram.model.TokenType
        Direction systemcomposer.activitydiagram.model.PortDirection
        ReferenceID char
    end

    methods
        function pinObj = Pin(type, direction, parent, name, externalID)
            arguments
                type
                direction 
                parent SysMLConnector.internal.CandidateAD.Node
                name
                externalID = [char(parent.ExternalID) '_' name];
            end

            % Ensure that the pin is given a unique name.
            if isempty(name)
                name = SysMLConnector.internal.utils.nextNameProperty(parent.Pins, 'Pin');
            else
                name = SysMLConnector.internal.utils.nextNameProperty(parent.Pins, name);
            end

            pinObj@SysMLConnector.internal.CandidateAD.Element(Name=name, ExternalID=externalID, Owner=parent);
            pinObj.ValidRequirementLinkTarget = true;
            pinObj.TokenType = type;
            pinObj.Direction = direction;
        end

        function  flow = connect(source, destination, guard, externalID)
            flow = SysMLConnector.internal.CandidateAD.internal.connect(source, destination, guard, externalID);
        end

        function doPublish(this, target)
            if isequal(this.TokenType, systemcomposer.activitydiagram.model.TokenType.CONTROL)
                % Do not create control pins.
                return;
            end

            isInput = isequal(this.Direction, systemcomposer.activitydiagram.model.PortDirection.INPUT);

            try
                activityPath = SysMLConnector.internal.CandidateAD.internal.getQualifiedName(target);

                this.BuiltElement = SysMLConnector.internal.CandidateAD.internal.addPin(activityPath, this.Name, isInput);
            catch
                % Try to recover 
                if ~isa(target.BuiltElement, 'systemcomposer.activitydiagram.model.Activity')
                    % Object Pins
                    this.BuiltElement = this.Owner.BuiltElement.Pins(strcmp({target.BuiltElement.Pins.Name}, this.Name));
                else
                    % Activity Parameters
                    this.BuiltElement = this.Owner.BuiltElement.Parameters(strcmp({target.BuiltElement.Parameters.Name}, this.Name));
                end
            end
        end

        function postPublish(this, target)
            % This is a basic heuristic to fix an invalid modeling semantic
            % where multiple flows are connected to this pin by inserting a
            % proxy merge/decision node.
            if isempty(this.Owner.Flows)
                return;
            end

            try
                flows = this.Owner.Flows;
                if this.Direction == systemcomposer.activitydiagram.model.PortDirection.OUTPUT
                    dirFlag = 'DestinationPin';
                    nameSuffix = '_Merge';
                    mergeDecisionExternalID = [char(this.ExtElementID) nameSuffix];
                    sourceID = mergeDecisionExternalID;
                    destinationID = this.ExternalID;
                else % Assume input
                    dirFlag = 'SourcePin';                
                    nameSuffix = '_Decision';
                    mergeDecisionExternalID = [char(this.ExtElementID) nameSuffix];
                    sourceID = this.ExternalID;
                    destinationID = mergeDecisionExternalID;
                end
    
                flowIndices = arrayfun(@(flow) flow.(dirFlag)==this, flows);

                if sum(flowIndices, 'all') > 1
                    % Multiple flows in or out of the pin so add a
                    % merge/decision node.
                    flows = flows(flowIndices);

                    mergeDecisionNode = SysMLConnector.internal.CandidateAD.MergeDecisionNode(Name = [this.Name nameSuffix], ...
                                                                                    ExternalID = mergeDecisionExternalID, ...
                                                                                    Owner = this.Owner);

                    publish(mergeDecisionNode, target);
    
                    proxyFlow = SysMLConnector.internal.CandidateAD.Flow('', sourceID, destinationID, ...
                                                                         Name = [this.Name '_ProxyFlow'], ...
                                                                         ExternalID = [char(this.ExtElementID) '_ProxyFlow'], ...
                                                                         Owner = this.Owner);

                    publish(proxyFlow, target);

                    % Finally, redirect the flows to the merge decision node
                    % instead of the pin.
                    set(flows, [dirFlag 'ID'], mergeDecisionNode.ExternalID);
                end
            catch ME
                warning('SysMLConnector:internal:CandidateAD:Pin:postPublish:ProxyMergeDecisionHeuristicFailed', 'A modeling issue was detected where multiple flows came off of ''%s'' but it was unable to be resolved due to error: ''%s''.', SysMLConnector.internal.CandidateAD.internal.getQualifiedName(this), ME.identifier);
            end
        end

        function prePrint(~,~)
        end

        function postPrint(~,~)
        end

        function doPrint(this, printer)
            printStr = sprintf('%s: [Type: %s, Direction: %s]', this.Name, char(this.TokenType), char(this.Direction));
            printer.print(string(printStr));
        end
    end
end