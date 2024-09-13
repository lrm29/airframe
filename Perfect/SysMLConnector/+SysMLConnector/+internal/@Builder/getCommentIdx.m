function commentIdx = getCommentIdx(this)
    %GETCOMMENTIDX returns the index
    arguments
        this SysMLConnector.internal.Builder
    end
    commentIdx = this.CommentIdx;
end