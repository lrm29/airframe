function ret = visitumlmmComment(~,element)
%VISITUMLMMCOMMENT visit comment
arguments
    ~
    element umlmm.Comment
end
ret =  [];
SysMLConnector.internal.CandidateComment.Comment(element);
end

