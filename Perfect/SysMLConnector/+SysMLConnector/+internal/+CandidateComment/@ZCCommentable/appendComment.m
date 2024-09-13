function appendComment(this,comment)
%APPENDCOMMENT appends to the description field of the ZCElement
arguments
    this SysMLConnector.internal.CandidateComment.ZCCommentable
    comment SysMLConnector.internal.CandidateComment.Comment
end
if this.Built
    this.appendToDescription(this.ZCElement.SimulinkHandle,comment);
end
end

