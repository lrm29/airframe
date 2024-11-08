function appendComment(this,comment)
%APPENDCOMMENT appends to the description field of the BuiltElement
arguments
    this SysMLConnector.internal.CandidateComment.ZCCommentable
    comment SysMLConnector.internal.CandidateComment.Comment
end
if this.Built
    this.appendToDescription(this.BuiltElement.SimulinkHandle,comment);
end
end

