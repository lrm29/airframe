classdef Message < SysMLConnector.internal.CandidateInteraction.Element & ...
        SysMLConnector.internal.CandidateInteraction.RelatedElementCommentable
    properties (SetAccess=protected)
        From 
        To 
        StartFragment
        EndFragment
        Invalid = false;
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
                Owner=parent);
            messageObj.From = SysMLConnector.internal.CandidateInteraction.Message.getEndPoint( ...
                parent.Interaction,umlMessage, 'sendEvent');
            messageObj.To = SysMLConnector.internal.CandidateInteraction.Message.getEndPoint( ...
                parent.Interaction,umlMessage, 'receiveEvent');
            messageObj.ValidRequirementLinkTarget = false;
            %% setup exclusions for printing
            messageObj.ExcludedProperties = [messageObj.ExcludedProperties,...
                "StartFragment","EndFragment"];
            %% check for comments
            messageObj.initializeComments(umlMessage);
        end

        doPublish(this, varargin);
        registerFragment(this, fragment);
        print(this,printer);
    end

    methods (Static)
        validateEndPoint(endPoint);
        endPoint = getEndPoint(candidateInteraction, messageOrEvent, eventName);
    end
end

