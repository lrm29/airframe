classdef Commentable < handle
    %COMMENTABLE class that defines interface for classes that can
    %apply comments

    methods (Static)
        comments = checkForComments(element);
    end

    methods (Abstract)
        appendComment(this,comment);
    end

    properties (SetAccess=protected)
        Comments = SysMLConnector.internal.CandidateComment.Comment.empty
    end

    methods (Access=protected)
        initializeComments(this,element);
    end
end