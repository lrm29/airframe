function notImported = build(this)
    %BUILD builds the comment
    arguments
        this SysMLConnector.internal.CandidateComment.Comment
    end

    notImported = [];
    
    if this.Valid
        if ~isempty(this.AnnotatedElementExtID)
            this.BuiltElement = cell(0,numel(this.AnnotatedElement));
            builtIdx = 0;

            try

                for i = 1:numel(this.AnnotatedElement)
                    annotated=false;

                    if isa(this.AnnotatedElement{i},...
                            "SysMLConnector.internal.CandidateComment.Commentable")
                        this.AnnotatedElement{i}.appendComment(this);

                        annotated=true;
                    elseif isa(this.AnnotatedElement{i},"SysMLConnector.internal.CandidateElement")
                        % try the link target first
                        SysMLConnector.internal.CandidateComment.ZCCommentable.appendToDescription(...
                            this.AnnotatedElement{i}.LinkTarget,this.Text);

                        annotated=true;
                    elseif ismember("BuiltElement",fieldnames(this.AnnotatedElement{i}))
                        % assume it is anyways
                        SysMLConnector.internal.CandidateComment.ZCCommentable.appendToDescription(...
                            this.AnnotatedElement{i}.BuiltElement.SimulinkHandle,this.Text);

                        annotated=true;
                    end

                    if annotated
                        builtIdx = builtIdx + 1;
                        this.BuiltElement{builtIdx} = this.AnnotatedElement{i};
                    end
                end
            catch ME
                notImported = this.createNotImported("Comment",...
                    sprintf(...
                    "Unable to add comment %s as it could not be assigned to an imported element.",...
                    this.ExtElementID));
            end

            if builtIdx > 0
                % Remove any trailing empties for comments that did not
                % succeed
                this.BuiltElement = this.BuiltElement(1:builtIdx);
            end
        else
            % do nothing as the owner was not imported
            this.Build = false;
        end
    else
        this.Build = false;
    end
end