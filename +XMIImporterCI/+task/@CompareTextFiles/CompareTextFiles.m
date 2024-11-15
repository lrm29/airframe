classdef CompareTextFiles < padv.Task
    %COMPARETEXTFILES Compares pairs of text files to each other

    methods
        function this = CompareTextFiles(options)
            %COMPARETEXTFILES Construct an instance of this class
            arguments
                options.Name = "Compare Text Files";
            end
            this@padv.Task(options.Name);
        end

        taskResult = run(this,inputArtifacts);
    end
end