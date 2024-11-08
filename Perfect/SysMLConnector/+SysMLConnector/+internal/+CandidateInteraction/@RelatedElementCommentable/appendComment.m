function appendComment(this,comment)
%APPENDCOMMENT Appends the comment to the related element with in System
%Composer
arguments
    this SysMLConnector.internal.CandidateInteraction.RelatedElementCommentable
    comment SysMLConnector.internal.CandidateComment.Comment
end
if this.Built
    relatedElements = this.BuiltElement.RelatedElements;
    arrayfun(@(re) this.appendToDescription(re.SimulinkHandle,comment.Text), ...
        relatedElements);
end
end

