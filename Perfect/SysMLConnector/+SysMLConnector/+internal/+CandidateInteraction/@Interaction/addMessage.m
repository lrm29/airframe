function message = addMessage(this,messageParent,umlMessage)
%ADDMESSAGE adds a message to the interaction
arguments
    this SysMLConnector.internal.CandidateInteraction.Interaction
    messageParent SysMLConnector.internal.CandidateInteraction.Fragment
    umlMessage umlmm.Message
end
message = SysMLConnector.internal.CandidateInteraction.Message(messageParent,umlMessage);
this.Messages = [this.Messages,message];
this.MessageMap(message.ExtElementID) = message;
end

