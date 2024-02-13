classdef findXMI < padv.Query
    %FINDXMI task that finds XMI files across all referenced projects
    
    properties (Access=protected)
        exclusions
    end
    
    methods
        function obj = findXMI(options)
            %FINDXMI Construct an instance of this class
            %
            % will find XMI files based on file type
            arguments
                options.exclusions = "";
            end
            obj@padv.Query(string.empty);
            obj.exclusions = options.exclusions;
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
                for reference = project.ProjectReferences
                    artifacts = [artifacts, obj.findXMIfiles(reference.Project)];
                end
            end
            % get file extensions for all files in the project
            [~,~,ext] = fileparts([project.Files.Path]);
            xmlFileIndx = strcmp(ext,".xml");
            artifactFiles = project.Files(xmlFileIndx);
            for file = artifactFiles
                [~,filename,~] = fileparts(file.Path);
                if ~ismember(filename,obj.exclusions)
                    % if not excluded add to artifacts
                    artifacts = [artifacts,padv.Artifact("other_file", ...
                        padv.util.ArtifactAddress(fullfile(file.Path)))];
                end
            end
        end
    end
end

