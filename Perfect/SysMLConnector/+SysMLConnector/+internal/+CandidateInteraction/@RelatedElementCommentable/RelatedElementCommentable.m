classdef RelatedElementCommentable < ...
        SysMLConnector.internal.CandidateComment.ZCCommentable
    %RELATEDELEMENTCOMMENTABLE Deals with sequence elements that have
    %related elements so the can have comments

    methods
        appendComment(this,comment);
    end
end

