function postPublish(this,varargin)
%POSTPUBLISH add a comment after the last thing
arguments
    this SysMLConnector.internal.CandidateInteraction.AnnotatedCommentable
end
arguments (Repeating)
    varargin
end
% create blank annotations for later
this.Annotations = arrayfun( ...
    @(c) this.Model.BuiltElement.addAnnotation(),this.Comments);
end

