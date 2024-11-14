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
        function obj = LineComparison(string1,string2)
            %LINECOMPARISON Construct an instance of this class
            arguments
                % expected to be the "old"
                string1 (1,1) string
                % expected to be the "new"
                string2 (1,1) string
            end
            obj.OldLines = strsplit(string1,newline);
            obj.NewLines = strsplit(string2,newline);
            indexOffset = 0;
            i = 1;
            while i < numel(obj.OldLines)
                if strcmp(obj.OldLines(i),obj.NewLines(i+indexOffset))
                    i = i + 1;
                else
                    % these lines don't match
                    % need to launch 2 searches
                    if i + indexOffset + 1 <= numel(obj.NewLines)
                        % one for an insertion, if the next line the old can be
                        % matched in the new possible insertion
                        linesInserted = find(ismember(obj.NewLines(i+indexOffset+1:end),obj.OldLines(i)),1);
                        % check for false positives for insertion
                        if ~isempty(linesInserted) && ...
                                all(ismember(obj.NewLines(i+indexOffset+1:i+indexOffset+linesInserted),obj.OldLines(i:end)))
                            % this means all of the inserted lines are
                            % actually in the old set
                            % that doesn't makes sense 
                            % this is a false positive triggered by a
                            % changed line
                            linesInserted = [];
                        end
                        % the other for deletions looks for the next new line
                        % to exist in the old lines
                        linesDeleted = find(ismember(obj.OldLines(i:end),obj.NewLines(i+indexOffset)),1)-1;
                        if isempty(linesDeleted) && isempty(linesInserted)
                            % neither an insert nor a delete, it's a
                            % modify
                            obj.Changes(end+1,1:2) = [i,i+indexOffset];
                            i = i + 1;
                        elseif isempty(linesInserted) || any(linesDeleted < linesInserted)
                            % at least one exists, deleted is smaller
                            % use that
                            deletedLines = i:(i+linesDeleted-1);
                            obj.Deletions = [obj.Deletions,deletedLines];
                            i = i + linesDeleted;
                            indexOffset = indexOffset - linesDeleted;
                        else
                            % either only insertion exists or it is
                            % less than deletion
                            insertedLines = (i+indexOffset):(i+indexOffset+linesInserted-1);
                            obj.Insertions = [obj.Insertions,insertedLines];
                            i = i + 1;
                            indexOffset = indexOffset + linesInserted;
                        end
                    end
                end
                if i + indexOffset > numel(obj.NewLines)
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
    end
end