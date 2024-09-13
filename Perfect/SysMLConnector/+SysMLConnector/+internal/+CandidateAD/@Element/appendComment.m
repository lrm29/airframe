function appendComment(this,comment)
%APPENDCOMMENT appends comment to link target
arguments
    this SysMLConnector.internal.CandidateAD.Element
    comment SysMLConnector.internal.CandidateComment.Comment
end
if this.Built
    SysMLConnector.internal.CandidateComment.ZCCommentable.appendToDescription(...
        this.LinkTarget,comment.Text);
end
end

