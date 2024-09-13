classdef AnnotatedCommentable < ...
        SysMLConnector.internal.CandidateComment.Commentable & ...
        SysMLConnector.internal.CandidateInteraction.Element
    %ANNOTATEDCOMMENTABLE helps add annotations to interactions

    properties (SetAccess=protected)
        Annotations
        AnnotationIdx = 1
    end
    
    methods
        function annotatedCommentableObj = AnnotatedCommentable(parent,element)
            %ANNOTATEDCOMMENTABLE Construct an instance of this class
            if ismember("name",fieldnames(element))
                name = element.name;
            else
                name = "";
            end
            annotatedCommentableObj@SysMLConnector.internal.CandidateInteraction.Element(...
                Name=name,...
                ExternalID=SysMLConnector.internal.utils.getExtID(element),...
                Parent=parent);
            %% initialize the comments
            annotatedCommentableObj.initializeComments(element);
        end

        appendComment(this,comment);
        postPublish(this, target);
    end
end

