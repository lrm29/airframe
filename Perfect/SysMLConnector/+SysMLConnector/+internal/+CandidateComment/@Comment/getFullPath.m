function fullPath =  getFullPath(this)
%GETFULLPATH gets a path from the annotated element if possible
arguments
    this SysMLConnector.internal.CandidateComment.Comment
end
try
    fullPath = this.AnnotatedElement{1}.getFullPath;
catch
    % if that does not work then fall back on the comment's ID
    fullPath = this.ExtElementID;
end

