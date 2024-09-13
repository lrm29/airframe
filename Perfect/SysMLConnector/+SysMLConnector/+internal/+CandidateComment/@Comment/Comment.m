classdef Comment < SysMLConnector.internal.CandidateElement
    %CANDIDATECOMMENT holds comment information during import

    properties (SetAccess=protected)
        Text = string.empty()
        AnnotatedElementExtID = string.empty()
        Valid logical
        Built logical = false
    end

    properties (SetAccess=protected,Dependent)
        AnnotatedElement
    end

    methods
        function commentObj = Comment(element)
            %CANDIDATECOMMENT Construct an instance of this class
            arguments
                element umlmm.Comment
            end
            extID = SysMLConnector.internal.utils.getExtID(element);
            numInMap = numel(SysMLConnector.internal.CandidateElement.idMap( ...
                "lookup",extID));
            xmiNode = SysMLConnector.internal.utils.getNode(element);
            numInGraph = 1+numel(xmiNode.Duplicates);
            commentObj@SysMLConnector.internal.CandidateElement(extID);
            commentObj.Valid = numInGraph > numInMap;
            commentObj.Text = string(element.body);
            commentObj.AnnotatedElementExtID = ...
                strings(element.annotatedElement.size,1);
            for i = 1:numel(commentObj.AnnotatedElement)
                commentObj.AnnotatedElementExtID(i) = ...
                    SysMLConnector.internal.utils.getExtID( ...
                    element.annotatedElement.at(i));
            end
        end

        function annotatedElements = get.AnnotatedElement(this)
            arguments
                this SysMLConnector.internal.CandidateComment.Comment
            end
            annotatedElements = {};
            if ~isempty(this.AnnotatedElementExtID)
                annotatedElements = arrayfun(@(ae) ...
                    SysMLConnector.internal.CandidateElement.idMap(...
                    "lookup",ae),this.AnnotatedElementExtID,...
                    UniformOutput=false);
            end
        end

        notImported = build(this);
        fullPath = getFullPath(this);
    end
end

