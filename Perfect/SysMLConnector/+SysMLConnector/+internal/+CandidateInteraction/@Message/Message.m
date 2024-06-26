classdef Message < SysMLConnector.internal.CandidateInteraction.Element
    properties (SetAccess=protected)
        From 
        To 
    end

    properties (SetAccess=protected)% Build Properties
        Built = false;
    end
    
    methods
        function messageObj = Message(parent,umlMessage)
            arguments
                parent SysMLConnector.internal.CandidateInteraction.Fragment
                umlMessage umlmm.Message
            end
            %MESSAGE Construct an instance of this class
            messageObj@SysMLConnector.internal.CandidateInteraction.Element( ...
                Name=umlMessage.name, ...
                ExternalID=SysMLConnector.internal.utils.getExtID(umlMessage), ...
                Parent=parent);
            messageObj.From = SysMLConnector.internal.CandidateInteraction.Message.getEndPoint( ...
                parent.Interaction,umlMessage.sendEvent);
            messageObj.To = SysMLConnector.internal.CandidateInteraction.Message.getEndPoint( ...
                parent.Interaction,umlMessage.receiveEvent);
            messageObj.ValidRequirementLinkTarget = false;
        end

        doPublish(this, varargin);
    end

    methods (Static)
        validateEndPoint(endPoint);
        endPoint = getEndPoint(candidateInteraction,event);
    end
end

