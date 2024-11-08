classdef Parameter < SysMLConnector.internal.CandidateAD.Pin
    methods
        function pinObj = Parameter(type, direction, parent, name, externalID)
            arguments
                type
                direction 
                parent SysMLConnector.internal.CandidateAD.Node
                name
                externalID = [char(parent.ExternalID) '_' name];
            end

            % Ensure that the pin is given a unique name.
            if isempty(name)
                name = SysMLConnector.internal.utils.nextNameProperty(parent.Parameters, 'Parameter');
            else
                name = SysMLConnector.internal.utils.nextNameProperty(parent.Parameters, name);
            end

            pinObj@SysMLConnector.internal.CandidateAD.Pin(type, direction, parent, name, externalID);
        end

        function doPublish(this, target)
            if isa(target, 'SysMLConnector.internal.CandidateAD.Model')
                % Create a root-level architecture port.
                doPublish@SysMLConnector.internal.CandidateAD.Pin(this, target);
            else
                % Model Reference so the parameters should already exist on
                % the architecture and just need to be located.
                pinIdx = find(strcmp(this.ReferenceID,{target.Pins.ReferenceID}));

                componentPort = [];

                if isempty(pinIdx)
                    % Unable to find a match by XMI ID, try one more time
                    % by name resolution.
                    foundPort = target.BuiltElement.getPin(this.Name);

                    % The pin and parameter are only a match if the port
                    % direction is the same.
                    if ~isempty(foundPort) && (this.Direction == foundPort.Direction)
                        componentPort = foundPort;
                    end
                else
                    componentPort = target.Pins(pinIdx).BuiltElement;

                    % Ensure the pin name on the component matches the
                    % parameter name. The name might not match if the pin
                    % name was undefined in the XMI file or did not match
                    % the parameter name due to malformed SysMLConnector.internal.
                    try
                        SysMLConnector.internal.CandidateAD.internal.setName(componentPort, this.Name);
                    catch ME
                        % Ignore duplicate name errors and do not try to
                        % resolve further.
                        if ~strcmp(ME.identifier, 'Simulink:blocks:DupBlockName')
                            rethrow(ME)
                        end
                    end
                end

                if isempty(componentPort)
                    targetArchElement = SysMLConnector.internal.CandidateAD.internal.getArchitecturePeer(target.BuiltElement);

                    warning('xmi:CandidateAD:Parameter:MalformedXMI', 'Pin with name ''%s'' could not be found on reference activity ''%s'' and will be created. This is usually from a malformed XMI file. It is recommended that you review <a href="matlab: open_system(''%s'') ">%s</a> to ensure it was imported as expected.', ...
                        this.Name, ...
                        targetArchElement.getQualifiedName, ...
                        targetArchElement.Model.Name, ...
                        target.Model.Name);

                    % The pin was never created (probably due to a
                    % malformed XMI file. Recover by creating the pin.
                    doPublish@SysMLConnector.internal.CandidateAD.Pin(this, target);

                    componentPort = target.BuiltElement.getPin(this.Name);
                end

                this.BuiltElement = componentPort.ParentNode.ChildActivity.getParameter(componentPort.Name);
            end
        end
    end
end
