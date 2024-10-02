function createComment(this,candComment)
%CREATECOMMENTS creates the comments
arguments
    this SysMLConnector.internal.Builder
    candComment SysMLConnector.internal.CandidateComment.Comment
end
if isscalar(candComment)
    SysMLConnector.internal.StatusMonitor.publishEvent('BuildComment', ...
        candComment.ExtElementID, ...
        'Building comment (%i of %i).', ...
        this.getCommentIdx(), this.CommentCount);
    notImported = candComment.build();
    if ~isempty(notImported)
        this.addNotImported(candComment,notImported.Type,notImported.Reason);
    end
    this.CommentCount = this.CommentCount + 1;
else
    arrayfun(@(cc) this.createComment(cc),candComment);
end