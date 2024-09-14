function initializeComments(this,element)
%INITIALIZECOMMENTS Initializes comments property
arguments
    this SysMLConnector.internal.CandidateComment.Commentable
    element 
end
this.Comments = this.checkForComments(element);
if ~isempty(this.Comments)
    this.Comments = this.Comments([this.Comments.Valid]);
end
end