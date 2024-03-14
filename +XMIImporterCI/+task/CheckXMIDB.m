classdef CheckXMIDB < padv.Task
    %CHECKXMIDB checks import agains xmidb

    properties
        processedUUIDs = {}
        ExternalUIDs = {}
    end

    methods
        function obj = CheckXMIDB(options)
            %CHECKXMIDB Construct an instance of this class
            %
            % depends on import task
            arguments
                % unique identifier for task
                options.Name = "Check XMI";
                % artifacts the task iterates over
                options.IterationQuery = ...
                    XMIImporterCI.query.findXMI();
                % input artifacts for the task
                options.InputQueries = ...
                    [padv.builtin.query.GetIterationArtifact,...
                    padv.builtin.query.GetOutputsOfDependentTask(Task="Import XMI")];
                % where the task outputs artifacts
                options.OutputDirectory = fullfile(...
                    '$DEFAULTOUTPUTDIR$','CheckXMI');
            end
            % call the constructor of the superclass
            obj@padv.Task(options.Name, ...
                IterationQuery=options.IterationQuery, ...
                InputQueries=options.InputQueries);
            obj.OutputDirectory = options.OutputDirectory;
        end

        function taskResult = run(obj,inputArtifacts)
            % run checks how the import worked
            taskResult = padv.TaskResult;
            taskResult.Status = padv.TaskStatus.Pass;
            % get working artifact
            xmiArtifact = XMIImporterCI.utilities.rerunQuery( ...
                obj.IterationQuery,inputArtifacts{1});
            % setup the xmidb
            xmidb = SysMLImport.internal.CandidateAD.internal.XMIDatabase(readstruct( ...
                xmiArtifact.ArtifactAddress.getFileAddress()));
            % find and load the report data
            archiveFilePath = string.empty();
            for artifact = inputArtifacts{2}
                if endsWith(artifact.ArtifactAddress.getFileAddress,".mat")
                    load(artifact.ArtifactAddress.getFileAddress)
                elseif endsWith(artifact.ArtifactAddress.getFileAddress,".mlproj")
                    % this is the project archive, but it should be in the
                    % same place as the project generated
                    archiveFilePath = artifact.ArtifactAddress.getFileAddress();
                end
            end
            % make sure we got the report
            if ~exist("report","var")
                taskResult.Status = padv.TaskStatus.Error;
                return;
            end
            % check that we found an archive in the output
            if isempty(archiveFilePath)
                % if not this means nothing was imported
                taskResult.Status = padv.TaskStatus.Pass;
                taskResult.ResultValues.Warn = 1;
                return;
                % pass with warning as nothing was imported
            end
            % now that everything else is ready
            % open the generated project and start loading stuff
            % need to see if anything in the database got imported
            % need to keep track of the process running this task
            processProject = currentProject;
            % need to open the generated project
            [importedPath,~,~] = fileparts(archiveFilePath);
            importedProject = openProject(importedPath);

            % name save file for later 
            outputFileName = importedProject.Name+"_checkData.mat";

            % need to find all the architectures (including activity
            % diagrams)
            importQuery = padv.builtin.query.FindModels;
            importedArtifacts = importQuery.run();
            elementDicitonary = dictionary;
            for i = 1:numel(importedArtifacts)
                try
                    model = systemcomposer.loadModel( ...
                        importedArtifacts(i).ArtifactAddress.getFileAddress());
                    % need to move back process project (hack to keep this file on
                    % path)
                    cd(processProject.RootFolder);
                    elements = obj.findElemetsWithExternalUID(model.Architecture);
                    elementDicitonary(...
                        string(...
                        cellfun(@(e) e.ExternalUID,elements,...
                        'UniformOutput',false))) ...
                        = elements;
                    % move back to keep things working
                    cd(importedProject.RootFolder);
                catch ME
                    warning(ME.message);
                end
            end
            %% need to analyse the collected data
            % need a list of expected items
            cd(processProject.RootFolder);
            explorer = XMIChecker.CandidateExplorer();
            cellfun(@(i) explorer.explore(i),report.imported);
            %% Validate imported data
            candidates = explorer.dictionary.values;
            validators = XMIChecker.Validator.build(candidates,xmidb,elementDicitonary);
            taskResult.ResultValues.Pass = sum(cellfun(@(v) v.pass,validators));
            taskResult.ResultValues.Warn = sum(cellfun(@(v) v.warn,validators));
            taskResult.ResultValues.Fail = sum(cellfun(@(v) v.fail,validators));
            %% TODO: need to find all the escapes 
            % that is the elements imported but not repoted 
            % these are additional warnings
            %% go back to the process project
            openProject(processProject.RootFolder);
            %% save important data
            outputFilePath = fullfile(obj.resolvePath(obj.OutputDirectory),...
                outputFileName);
            if ~exist(obj.resolvePath(obj.OutputDirectory),"dir")
                mkdir(obj.resolvePath(obj.OutputDirectory));
            end
            save(outputFilePath,"validators","xmidb","elementDicitonary");
            taskResult.OutputPaths = outputFilePath;
            %% re-open process advisor window
            processAdvisorWindow();
        end

        function elements = findElemetsWithExternalUID(obj,element)
            % navigates through a system composer architecture and finds
            % all elements with externalID
            %
            %
            % check if element is an array if so deal with it
            if isscalar(element)
                % get the properties of this element
                properties = fieldnames(element);
                % first make sure this is an System Composer and has not
                % been processed
                if ismember("UUID",properties)
                    if ismember(element.UUID,obj.processedUUIDs)
                        % if this is has been processed already skip it
                        elements = cell.empty();
                        return;
                    else
                        obj.processedUUIDs{end+1} = element.UUID;
                        % don't need to check that one
                        properties = properties(~ismember(properties,"UUID"));
                        % need to check for possible reference, that is a
                        % dynamic property that causes errors
                        if ismember("ReferenceName",properties) && ...
                                ~element.isReference
                            properties = properties( ...
                                ~ismember(properties,"ReferenceName"));
                        end
                        % next setup cell array for output
                        elements = cell(size(properties));
                        % now go through the fields
                        for i = 1:numel(properties)
                            try
                                if isobject(element.(properties{i}))
                                    % call self
                                    elements{i} = ...
                                        obj.findElemetsWithExternalUID( ...
                                        element.(properties{i}));
                                else
                                    % if the field is not an object it's not an element
                                    % it is a property so check if it's ExternalID
                                    if strcmp(properties{i},"ExternalUID")
                                        if ~isempty(element.(properties{i}))
                                            % have a valid ExternalUID
                                            elements{i} = element;
                                            obj.ExternalUIDs{end+1} = ...
                                                element.ExternalUID;
                                        end
                                    end
                                end
                            catch ME
                                warning(ME.message);
                            end
                        end
                    end
                else
                    % not sure what this is but no UUID no processing
                    elements = cell.empty();
                    return;
                end
            else
                elements = cell(size(element));
                for i = 1:numel(elements)
                    elements{i} = ...
                        obj.findElemetsWithExternalUID(element(i));
                end
            end
            % move empty cells to simplify return
            if ~isempty(elements)
                elements = elements(~cellfun(@isempty,elements));
                % flatten the cell array
                elements = [elements{cellfun(@iscell,elements)},...
                    elements(~cellfun(@iscell,elements))];
            end
        end
    end
end

