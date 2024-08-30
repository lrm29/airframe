classdef ExportArchitecture < padv.Task & XMIImporterCI.utilities.PathManager
    %EXPORTARCHITECTURE Exports Architectures to test the export function

    methods
        function exportArchitectureObj = ExportArchitecture(options)
            %EXPORTARCHITECTURE Construct an instance of this class
            arguments
                % unique identifier
                options.Name = "Export Architecture";
                % setup iteration query
                options.IterationQuery = ...
                    XMIImporterCI.query.findByExtension(extension=".xml");
                % input artifacts for the task
                options.InputQueries = ...
                    padv.builtin.query.GetIterationArtifact;
                % where the task outputs artifacts
                options.OutputDirectory = fullfile(...
                    "$DEFAULTOUTPUTDIR$","ExportArchitectures", ...
                    "$ITERATIONARTIFACT$");
                % dependencies just incase
                options.InputDependencyQuery = padv.Query.empty();
            end
            % add self to the dependency list
            options.InputDependencyQuery = citools.query.GetDependencies(...
                XMIImporterCI.query.multiQuery(...
                [options.InputDependencyQuery,...
                citools.query.FindArtifactMFilePath( ...
                string(mfilename("fullpath")))]));
            % call parent constructor
            exportArchitectureObj@padv.Task(options.Name,...
                IterationQuery=options.IterationQuery,...
                InputQueries=options.InputQueries,...
                InputDependencyQuery=options.InputDependencyQuery);
            exportArchitectureObj.OutputDirectory = options.OutputDirectory;
        end

        function taskResult = run(this,inputArtifacts)
            % run exports architectures
            arguments
                this XMIImporterCI.task.ExportArchitecture
                inputArtifacts
            end
            taskResult = padv.TaskResult;
            taskResult.Status = padv.TaskStatus.Pass;

            %% check for open SLDD files
            % can cause errors
            taskResult.ResultValues.Warn = taskResult.ResultValues.Warn + ...
                XMIImporterCI.utilities.closeDataDictionaries();

            %% find artifacts so the imported project can be opened
            try
                archiveFilePath = string.empty();
                for artifact = inputArtifacts{2}
                    if endsWith(artifact.ArtifactAddress.getFileAddress,".mlproj")
                        archiveFilePath = artifact.ArtifactAddress.getFileAddress();
                        break;
                    end
                end
            catch ME
                disp(ME.message);
                disp(ME.getReport());
                for i = 1:numel(ME.stack)
                    disp(ME.stack(i));
                end
                taskResult.Status = padv.TaskStatus.Error;
                return;
            end

            %% determine paths for later
            outputPath = this.resolvePath(this.OutputDirectory);

            %% now load the imported project
            [importedPath,~,~] = fileparts(archiveFilePath);
            importedPath = fullfile(this.Project.RootFolder,importedPath);
            this.leaveProject();
            % need to open the generated project
            importedProject = openProject(importedPath);

            %% go back
            this.reopenProject();
        end
    end
end

