classdef Parameter < CandidateAD.Pin
    methods
        function pinObj = Parameter(type, direction, parent, name, externalID)
            arguments
                type
                direction 
                parent CandidateAD.Node
                name = ADBuilder.internal.nextNameProperty(parent.Pins, 'Pin');
                externalID = [char(parent.ExternalID) '_' name];
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
                this.ZCElement = componentPort.ParentNode.ChildActivity.getParameter(this.Name);
            end
        end
    end
end
