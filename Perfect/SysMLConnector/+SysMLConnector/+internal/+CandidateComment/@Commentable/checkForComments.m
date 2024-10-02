function comments = checkForComments(element)
%CHECKFORCOMMENTS checks if the element has owned comments and creates
%them
comments = SysMLConnector.internal.CandidateComment.Comment.empty();
if ismember("ownedComment",fieldnames(element))
    comments = ...
        SysMLConnector.internal.CandidateComment.Comment.empty( ...
        element.ownedComment.size,0);
    for i = 1:element.ownedComment.size
        comments(i) = SysMLConnector.internal.CandidateComment.Comment(...
            element.ownedComment.at(i));
    end
end
end

