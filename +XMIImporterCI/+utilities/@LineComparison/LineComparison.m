classdef LineComparison < handle
    %LINECOMPARISON Compares two strings line by line

    properties (SetAccess=protected)
        Insertions
        Deletions
        Changes
        OldLines string
        NewLines string
    end

    properties (SetAccess=protected,Dependent)
        Identical
    end

    methods
        function this = LineComparison(string1,string2)
            %LINECOMPARISON Construct an instance of this class
            arguments
                % expected to be the "old"
                string1 (1,1) string
                % expected to be the "new"
                string2 (1,1) string
            end
            this.OldLines = strsplit(string1,newline);
            this.NewLines = strsplit(string2,newline);
            indexOffset = 0;
            i = 1;
            while i < numel(this.OldLines)
                if strcmp(this.OldLines(i),this.NewLines(i+indexOffset))
                    i = i + 1;
                else
                    % these lines don't match
                    % need to launch 2 searches
                    if i + indexOffset + 1 <= numel(this.NewLines)
                        % one for an insertion, if the next line the old can be
                        % matched in the new possible insertion
                        linesInserted = find(ismember(this.NewLines(i+indexOffset+1:end),this.OldLines(i)),1);
                        % check for false positives for insertion
                        if ~isempty(linesInserted) && ...
                                all(ismember(this.NewLines(i+indexOffset+1:i+indexOffset+linesInserted),this.OldLines(i:i+linesInserted)))
                            % this means all of the inserted lines are
                            % actually in the old set
                            % that doesn't makes sense 
                            % this is a false positive triggered by a
                            % changed line
                            linesInserted = [];
                        end
                        % the other for deletions looks for the next new line
                        % to exist in the old lines
                        linesDeleted = find(ismember(this.OldLines(i:end),this.NewLines(i+indexOffset)),1)-1;
                        if isempty(linesDeleted) && isempty(linesInserted)
                            % neither an insert nor a delete, it's a
                            % modify
                            this.Changes(end+1,1:2) = [i,i+indexOffset];
                            i = i + 1;
                        elseif isempty(linesInserted) || any(linesDeleted < linesInserted)
                            % at least one exists, deleted is smaller
                            % use that
                            deletedLines = i:(i+linesDeleted-1);
                            this.Deletions = vertcat(this.Deletions, ...
                                [deletedLines', ...
                                ones(size(deletedLines'))*(i+indexOffset)]);
                            i = i + linesDeleted;
                            indexOffset = indexOffset - linesDeleted;
                        else
                            % either only insertion exists or it is
                            % less than deletion
                            insertedLines = (i+indexOffset):(i+indexOffset+linesInserted-1);
                            this.Insertions = vertcat(this.Insertions,...
                                [{i},{insertedLines'}]);
                            i = i + 1;
                            indexOffset = indexOffset + linesInserted;
                        end
                    end
                end
                if i + indexOffset > numel(this.NewLines)
                    break
                end
            end
        end

        function value = get.Identical(this)
            arguments
                this XMIImporterCI.utilities.LineComparison
            end
            value = isempty(this.Changes) && isempty(this.Deletions) && isempty(this.Insertions);
        end

        print(this);
    end
end