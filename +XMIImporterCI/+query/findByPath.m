classdef findByPath < padv.Query
    %FINDBYPATH finds a file on the path within the current project
   
    properties (Access=protected)
        filePath
        ArtifactType
    end
    
    methods
        function obj = findByPath(options)
            %FINDBYPATH Construct an instance of this class
            arguments
                options.filePath
                options.ArtifactType
            end
            obj@padv.Query(string.empty);
            obj.filePath = options.filePath;
            obj.ArtifactType = options.ArtifactType;
        end
        
        function artifacts = run(obj,~)
            % run finds artifact by path
            %
            project = currentProject();
            artifacts = padv.Artifact(obj.ArtifactType,...
                padv.util.ArtifactAddress(fullfile(obj.filePath),...
                OwningProjectName=project.Name));
        end
    end
end

