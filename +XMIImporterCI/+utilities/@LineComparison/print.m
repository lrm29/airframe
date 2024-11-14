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
        fprintf("Lines inserted before original line %d:\n",this.Insertions{i,1});
        for j = 1:numel(this.Insertions{i,2})
            fprintf("%d: %s\n",this.Insertions{i,2}(j),...
                this.NewLines(this.Insertions{i,2}(j)));
        end
    end
end
end