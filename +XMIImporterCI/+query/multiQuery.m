classdef multiQuery < padv.Query
    %MULTIQUERY allow mulitple queries to be presented as one
    
    properties (Access = protected)
        queries
    end
    
    methods
        function obj = multiQuery(queries)
            %MULTIQUERY Construct an instance of this class
            % takes an array of queries and 
            obj@padv.Query(string.empty);
            obj.queries = queries;
        end

        function artifacts = run(obj,~)
            % runs all queries and returns artifacts
            %
            artifacts = arrayfun(@(q) q.run(),obj.queries, ...
                UniformOutput=false);
            % expand the cell array
            artifacts = [artifacts{:}];
        end
    end
end

