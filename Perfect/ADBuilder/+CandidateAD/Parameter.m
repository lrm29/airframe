classdef Parameter < CandidateAD.Pin
    methods
        function pinObj = Parameter(type, direction, parent, name, externalID)
            arguments
                type
                direction 
                parent CandidateAD.Node
                name
                externalID = [char(parent.ExternalID) '_' name];
            end

            % Ensure that the pin is given a unique name.
            if isempty(name)
                name = ADBuilder.internal.nextNameProperty(parent.Parameters, 'Parameter');
            else
                name = ADBuilder.internal.nextNameProperty(parent.Parameters, name);
            end

            pinObj@CandidateAD.Pin(type, direction, parent, name, externalID);
        end

        function doPublish(this, target)
            if isa(target, 'CandidateAD.Model')
                % Create a root-level architecture port.
                doPublish@CandidateAD.Pin(this, target);
            else
                % Model Reference so the parameters should already exist on the architecture and just need to be located.
                componentPort = target.ZCElement.getPin(this.Name);

                if isempty(componentPort)
                    targetArchElement = ADBuilder.internal.getArchitecturePeer(target.ZCElement);

                    warning('CandidateAD:Parameter:MalformedXMI', 'Pin with name ''%s'' could not be found on reference activity ''%s'' and will be created. This is usually from a malformed XMI file. It is recommended that you review <a href="matlab: open_system(''%s'') ">%s</a> to ensure it was imported as expected.', ...
                        this.Name, ...
                        targetArchElement.getQualifiedName, ...
                        targetArchElement.Model.Name, ...
                        target.Model.Name);
                    % The pin was never created (probably due to a
                    % malformed XMI file. Recover by creating the pin.
                    doPublish@CandidateAD.Pin(this, target);

                    componentPort = target.ZCElement.getPin(this.Name);
                end

                this.ZCElement = componentPort.ParentNode.ChildActivity.getParameter(this.Name);
            end
        end
    end
end
