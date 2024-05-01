classdef findByExtension < padv.Query
    %FINDXMI task that finds XMI files across all referenced projects
    
    properties (Access=protected)
        exclusions
        extension
        inclusions
    end
    
    methods
        function obj = findByExtension(options)
            %FINDXMI Construct an instance of this class
            %
            % will find XMI files based on file type
            arguments
                options.exclusions = "";
                options.extension = ".xml";
                options.inclusions = string.empty()
            end
            obj@padv.Query(string.empty);
            obj.exclusions = options.exclusions;
            obj.extension = options.extension;
            obj.inclusions = options.inclusions;
        end

        function artifacts = run(obj,~)        
            % run finds artifacts that are XMI files
            %
            % looks at extension
            artifacts = obj.findExtFile(currentProject);
        end
    end

    methods (Access=protected)
        function artifacts = findExtFile(obj,project)
            % finds artifacts in the project passed
            %
            % will recurse through all projects below
            artifacts = [];
            if ~isempty(project.ProjectReferences)
                for reference = project.ProjectReferences
                    artifacts = [artifacts, obj.findExtFile(reference.Project)];
                end
            end
            % get file extensions for all files in the project
            [~,~,ext] = fileparts([project.Files.Path]);
            xmlFileIndx = strcmp(ext,obj.extension);
            artifactFiles = project.Files(xmlFileIndx);
            for file = artifactFiles
                [~,filename,~] = fileparts(file.Path);
                %% check inculsion filter
                if ~isempty(obj.inclusions) && ...
                        ~ismember(filename,obj.inclusions)
                    % if there are inclusions and this file is not included
                    % skip this file
                    continue;
                end
                %% check exculsion filter
                if ~ismember(filename,obj.exclusions)
                    % if not excluded add to artifacts
                    artifacts = [artifacts,padv.Artifact("other_file", ...
                        padv.util.ArtifactAddress(fullfile(file.Path),...
                        OwningProjectName=project.Name))];
                end
            end
        end
    end
end

