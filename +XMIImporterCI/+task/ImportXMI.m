classdef ImportXMI < padv.Task
    %IMPORTXMI runs the updated XMI importer of XMI files


    methods
        function obj = ImportXMI(options)
            %IMPORTXMI Construct an instance of this class
            %
            % uses the XMIImporterCI.query.findXMI by default query to find XML files
            arguments
                % unique identifier for task
                options.Name = "Import XMI";
                % artifacts the task iterates over
                options.IterationQuery = ...
                    XMIImporterCI.query.findXMI();
                % input artifacts for the task
                options.InputQueries = ...
                    padv.builtin.query.GetIterationArtifact;
                % where the task outputs artifacts
                options.OutputDirectory = fullfile(...
                    '$DEFAULTOUTPUTDIR$','XMIImport');
                % this depends on files in the Perfect directory so need to
                % trigger if those change
                options.InputDependencyQuery = ...
                    padv.builtin.query.FindArtifacts(ArtifactType="m_file",...
                    IncludePath="Perfect");
            end
            % call the constructor of the superclass
            obj@padv.Task(options.Name, ...
                IterationQuery=options.IterationQuery, ...
                InputQueries=options.InputQueries, ...
                InputDependencyQuery=options.InputDependencyQuery);
            obj.OutputDirectory = options.OutputDirectory;
        end

        function taskResult = run(obj,inputArtifacts)
            % imports XMI files and reports if successful
            taskResult = padv.TaskResult;
            taskResult.Status = padv.TaskStatus.Pass;
            project = currentProject;

            %% TODO: fix this
            % need to check with development this isn't right
            % re-running query to get what I need
            query = XMIImporterCI.query.findXMI();
            realArtifacts = query.run();
            artifactToUse = [];
            reportedPath = inputArtifacts{1}.ArtifactAddress.getFileAddress();
            reportedPath = strrep(reportedPath,"/",filesep);
            for artifact = realArtifacts
                if endsWith(artifact.ArtifactAddress.getFileAddress, reportedPath)
                    % found the real artifact
                    artifactToUse = artifact;
                    break;
                end
            end
            if isempty(artifactToUse)
                % could not find XML file
                taskResult.Status = padv.TaskStatus.Error;
                return;
            else
                %% need to find where the output will be 
                [~,xmiName,~] = fileparts( ...
                    artifactToUse.ArtifactAddress.getFileAddress());
                outputProjectPath = obj.resolvePath(obj.OutputDirectory)+ ...
                    string(filesep)+xmiName;
                % we have the file, need to make sure the result directory
                % exists
                if ~exist(obj.resolvePath(obj.OutputDirectory),"dir")
                    mkdir(obj.resolvePath(obj.OutputDirectory));
                else
                    % this means that the output directory existed
                    % now we have to make sure that the imported project
                    % isn't already there
                    if exist(outputProjectPath,"dir")
                        % if this directory exists it must be removed
                        rmdir(outputProjectPath,"s");
                    end
                end
            end
            %% Ideal is for it to be just this
            try
                % need to store the resolved path, resolving gets weird
                % once the project is closed on linux
                outputDirectory = obj.resolvePath(obj.OutputDirectory);
                %% add tools to path
                close(project);
                oldPath = addpath(genpath( ...
                    strjoin([project.RootFolder,"Perfect"],filesep)));
                fprintf('***Importing file ''%s''...\n', ...
                    artifactToUse.ArtifactAddress.getFileAddress);
                report = xmi.import( ...
                    artifactToUse.ArtifactAddress.getFileAddress, ...
                    outputDirectory); %#ok<NASGU>
                fprintf('***Import complete for ''%s''.\n', ...
                    artifactToUse.ArtifactAddress.getFileAddress);
                %% setup output path
                if exist(outputProjectPath+"_report.txt","file")
                    % taskResult.OutputPaths = ...
                    %     outputProjectPath+"_report.txt";
                end
            catch ME
                taskResult.Details = ME;
                taskResult.Status = padv.TaskStatus.Fail;
                fprintf('Error: ''%s''\n%s\n', ME.identifier, getReport(ME));
                fprintf('***Import failed for ''%s''.\n', ...
                    artifactToUse.ArtifactAddress.getFileAddress);
            end
            %% remove tools from path
            path(oldPath);
            openProject(project.RootFolder);
            processAdvisorWindow();
        end
    end
end

