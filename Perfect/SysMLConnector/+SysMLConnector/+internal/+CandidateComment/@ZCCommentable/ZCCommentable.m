classdef ZCCommentable < SysMLConnector.internal.CandidateComment.Commentable
    %ZCCOMMENTABLE for classes that have a ZC element so they can have
    %comments applied

    properties (Abstract,SetAccess=protected)
        ZCElement
        Built
    end
    
    methods
        appendComment(this,comment);
    end

    methods (Static)
        appendToDescription(simulinkHandle,text);
    end
end

