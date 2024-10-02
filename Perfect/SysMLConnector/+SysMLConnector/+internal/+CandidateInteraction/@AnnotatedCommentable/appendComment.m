function appendComment(this,Comment)
%APPENDCOMMENT fill in the annotation made earlier
arguments
    this SysMLConnector.internal.CandidateInteraction.AnnotatedCommentable
    Comment SysMLConnector.internal.CandidateComment.Comment
end
this.Annotations(this.AnnotationIdx).Content = Comment.Text;
this.AnnotationIdx = this.AnnotationIdx + 1;
end

