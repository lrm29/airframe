function print(this)
%PRINT Prints a summary of the differences if any
arguments
    this XMIImporterCI.utilities.LineComparison
end
if this.Identical
    disp("The strings are identical");
else
    % real work
    for i = 1:size(this.Insertions,1)
        fprintf("Lines inserted after original line %d:\n",this.Insertions{i,1});
        for j = 1:numel(this.Insertions{i,2})
            fprintf("%d: %s\n",this.Insertions{i,2}(j),...
                this.NewLines(this.Insertions{i,2}(j)));
        end
    end
    for i = 1:size(this.Deletions,1)
        linesDeleted = numel(this.Deletions{i,1});
        if linesDeleted > 1
            fprintf("Lines %d to %d deleted from original:\n", ...
                this.Deletions{i,1}(1),this.Deletions{i,1}(end));
        else
            % only one line
            fprintf("Line %d deleted from original:\n",this.Deletions{i,1});
        end
        for j = 1:linesDeleted
            fprintf("%d: %s\n",this.Deletions{i,1}(j), ...
                this.OldLines(this.Deletions{i,1}(j)));
        end
    end
    for i = 1:size(this.Changes,1)
        fprintf("Line %d changed from:\n",this.Changes(i,1));
        fprintf("%d: %s\n",this.Changes(i,1),this.OldLines(this.Changes(i,1)));
        fprintf("To:\n");
        fprintf("%d: %s\n",this.Changes(i,2),this.NewLines(this.Changes(i,2)));
    end
end
end