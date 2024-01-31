classdef findXMI < padv.Query
    %FINDXMI task that finds XMI files across all referenced projects
    
    
    methods
        function obj = findXMI()
            %FINDXMI Construct an instance of this class
            %
            % will find XMI files based on file type
            obj@padv.Query(string.empty);
        end

        function artifacts = run(obj,~)        
            % run finds artifacts that are XMI files
            %
            % looks at extension
            artifacts = obj.findXMIfiles(currentProject);
        end
    end

    methods (Access=protected)
        function artifacts = findXMIfiles(obj,project)
            % finds artifacts in the project passed
            %
            % will recurse through all projects below
            artifacts = [];
            if ~isempty(project.ProjectReferences)
                for reference = project.ProjectReferences.Project
                    artifacts = [artifacts, obj.findXMIfiles(reference)];
                end
            end
            % get file extensions for all files in the project
            [~,~,ext] = fileparts([project.Files.Path]);
            xmlFileIndx = strcmp(ext,".xml");
            artifactFiles = project.Files(xmlFileIndx);
            for file = artifactFiles
                artifacts = [artifacts,padv.Artifact("other_file",file.Path)];
            end
        end
    end
end

