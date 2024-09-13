function notImported = build(this)
%BUILD builds the comment
arguments
    this SysMLConnector.internal.CandidateComment.Comment
end
notImported = [];
if this.Valid
    if ~isempty(this.AnnotatedElementExtID)
        try
            for i = 1:numel(this.AnnotatedElement)
                if isa(this.AnnotatedElement{i},...
                        "SysMLConnector.internal.CandidateComment.Commentable")
                    this.AnnotatedElement{i}.appendComment(this);
                elseif isa(this.AnnotatedElement{i},"SysMLConnector.internal.CandidateElement")
                    % try the link target first
                    SysMLConnector.internal.CandidateComment.ZCCommentable.appendToDescription(...
                        this.AnnotatedElement{i}.LinkTarget,this.Text);
                elseif ismember("ZCElement",fieldnames(this.AnnotatedElement{i}))
                    % assume it is anyways
                    SysMLConnector.internal.CandidateComment.ZCCommentable.appendToDescription(...
                        this.AnnotatedElement{i}.ZCElement.SimulinkHandle,this.Text);
                end
            end
            this.Built = true;
        catch
            notImported = this.createNotImported("Comment",...
                sprintf(...
                "Unable to add comment %s as it could not be assigned to an imported element.",...
                this.ExtElementID));
        end
    else
        % do nothing as the owner was not imported
    end
end
end