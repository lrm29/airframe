function validateEndPoint(endPoint)
%VALIDATEENDPOINT validates that the end point is a valid type for Message
if ~(isa(endPoint,"SysMLConnector.internal.CandidateInteraction.Interaction") || ...
        isa(endPoint,"SysMLConnector.internal.CandidateInteraction.Lifeline"))
    errorID = "SysmlConnector:CandidateInteraction:Message:InvalidEndPoint";
    errorMsg = sprintf("%s is not a valid end point type.",class(endPoint));
    errorMsg(errorID,errorMsg);
end

