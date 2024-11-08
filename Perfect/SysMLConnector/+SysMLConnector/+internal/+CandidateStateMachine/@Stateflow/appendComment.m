function appendComment(this,comment)
%APPENDCOMMENT appends comment to state machine element
arguments
    this SysMLConnector.internal.CandidateStateMachine.Element
    comment SysMLConnector.internal.CandidateComment.Comment
end
if this.Built
    this.BuiltElement.Description = [this.BuiltElement.Description,...
        char(comment.Text)];
end
end

