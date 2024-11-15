classdef CompareTextFiles < padv.Task
    %COMPARETEXTFILES Compares pairs of text files to each other

    properties (SetAccess=protected)
        NiceMode logical
    end

    methods
        function this = CompareTextFiles(options)
            %COMPARETEXTFILES Construct an instance of this class
            arguments
                options.Name = "Compare Text Files";
                % need two input queries
                options.InputQuery1 padv.Query
                options.InputQuery2 padv.Query
                % optional iteration query to handle iterations
                options.IterationQuery padv.Query = padv.Query.empty()
                % need an option to make nice when needed
                options.NiceMode logical = true
            end
            this@padv.Task(options.Name,...
                InputQueries=[options.InputQuery1,options.InputQuery2],...
                IterationQuery=options.IterationQuery);
            this.NiceMode = options.NiceMode;
        end

        taskResult = run(this,inputArtifacts);
    end
end