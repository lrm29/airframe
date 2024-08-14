classdef CheckXMIDB < padv.Task
    %CHECKXMIDB checks import agains xmidb

    properties
        processedUUIDs = {}
        ExternalUIDs = {}
        nice = false;
        report = true;
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
                    XMIImporterCI.query.findByExtension(extension=".xml");
                % input artifacts for the task
                options.InputQueries = ...
                    padv.builtin.query.GetIterationArtifact;
                % where the task outputs artifacts
                options.OutputDirectory = fullfile(...
                    '$DEFAULTOUTPUTDIR$','CheckXMI');
                % dependencies just incase
                options.InputDependencyQuery = padv.Query.empty();
                % Nice makes the task not fail on error
                options.Nice = false;
                % reporting on by default
                options.report = true;
            end
            % add self to the dependency list
            options.InputDependencyQuery = XMIImporterCI.query.multiQuery(...
                [options.InputDependencyQuery,...
                XMIImporterCI.query.findByPath(ArtifactType="m_file",...
                filePath=string(mfilename("fullpath"))+".m"),...
                padv.builtin.query.FindArtifacts(ArtifactType="m_file",...
                IncludePath="XMIChecker")]);
            % call the constructor of the superclass
            obj@padv.Task(options.Name, ...
                IterationQuery=options.IterationQuery, ...
                InputQueries=options.InputQueries,...
                InputDependencyQuery=options.InputDependencyQuery);
            obj.OutputDirectory = options.OutputDirectory;
            obj.nice = options.Nice;
            obj.report = options.report;
        end

        function taskResult = run(obj,inputArtifacts)
            % run checks how the import worked
            taskResult = padv.TaskResult;
            taskResult.Status = padv.TaskStatus.Pass;

            warnState = warning('off', 'Slvnv:slreq:illegalDataForMATFile');
            cleanupWarning = onCleanup(@() warning(warnState));

            %% check for open SLDD files
            % can cause errors
            if ~isempty(Simulink.data.dictionary.getOpenDictionaryPaths)
                openDDs = Simulink.data.dictionary.getOpenDictionaryPaths();
                cellfun( ...
                    @(odd) warning("Data dictionary %s was left open and will be closed.",odd), ...
                    openDDs);
                taskResult.ResultValues.Warn = taskResult.ResultValues.Warn + ...
                    numel(openDDs);
                Simulink.data.dictionary.closeAll('-discard');
            end

            try
                % make sure output exists
                if ~exist(obj.resolvePath(obj.OutputDirectory),"dir")
                    mkdir(obj.resolvePath(obj.OutputDirectory));
                end
                % get working artifact
                xmiArtifact = XMIImporterCI.utilities.rerunQuery( ...
                    obj.IterationQuery,inputArtifacts{1});
                % check if this artifact is an MDZip file and if so convert
                xmiArtifactFilepath = ...
                    xmiArtifact.ArtifactAddress.getFileAddress();
                [~,xmiFileName,ext] = fileparts(xmiArtifactFilepath);
                if strcmp(ext,".mdzip")
                    xmiFilePath = fullfile( ...
                        obj.resolvePath(obj.OutputDirectory),xmiFileName+".xml");
                    if exist(xmiFilePath,"file")
                        % need to clear the old XMI file extracted
                        delete(xmiFilePath);
                    end
                    xmiArtifactFilepath = ...
                        SysMLConnector.internal.utils.getModelFile( ...
                        xmiArtifactFilepath, ...
                        obj.resolvePath(obj.OutputDirectory));
                    saveXMI = true;
                else
                    saveXMI = false;
                end
                % setup the xmidb
                xmidb = ...
                    SysMLConnector.internal.CandidateAD.internal.XMIDatabase( ...
                    readstruct(xmiArtifactFilepath));
                % record starting point to restore later
                startingPoint = pwd;
                processProject = currentProject();
                %% back to checking
                cd(processProject.RootFolder);
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
                % before anything else need to get the path to the imported
                % project
                [importedPath,~,~] = fileparts(archiveFilePath);
                importedPath = fullfile(processProject.RootFolder,importedPath);
                % now that everything else is ready
                % open the generated project and start loading stuff
                % need to see if anything in the database got imported
                % need to keep track of the process running this task
                % add project path to path
                processPath = processProject.ProjectPath;
                % close porject and save off original path
                processProject.close();
                originalPath = path;
                arrayfun(@(f) addpath(f.File),processPath);
                % need to open the generated project
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
                        if ~isempty(model)
                            if isMATLABReleaseOlderThan("R2024b")
                                elements = obj.findElemetsWithExternalUID(...
                                    {model.Architecture, ...
                                    model.InterfaceDictionary.Interfaces,...
                                    model.Views,model.Profiles});
                            else
                                elements = obj.findElemetsWithExternalUID(...
                                    {model.Architecture, ...
                                    model.InterfaceDictionary.Interfaces,...
                                    model.Interactions,model.Views,model.Profiles});
                            end
                            elementDicitonary(...
                                string(...
                                cellfun(@(e) e.ExternalUID,elements,...
                                'UniformOutput',false))) ...
                                = elements;
                        end
                    catch ME
                        warning(ME.message);
                    end
                end
                %% parse Stateflow
                % above should have loaded all the models so this just has
                % to find the elements that where imported
                stateMachineParts = find(sfroot);
                for i = 1:numel(stateMachineParts)
                    % determine if each part has a Documents field and if
                    % it has anything in it
                    fields = fieldnames(stateMachineParts(i));
                    if ismember("Document",fields)
                        if ~strcmp(stateMachineParts(i).Document,'')
                            % going to assume this is an ID
                            elementDicitonary(...
                                string(stateMachineParts(i).Document)) = ...
                                {stateMachineParts(i)};
                        end
                    end
                end
                %% need to analyse the collected data
                explorer = XMIChecker.CandidateExplorer();
                explorer.explore(report.imported); %#ok<PROPLC> "report" is loaded from mat file
                %% Validate imported data
                candidates = explorer.dictionary.values;
                validators = XMIChecker.Validator.build(candidates,xmidb,elementDicitonary);
                taskResult.ResultValues.Pass = sum(cellfun(@(v) v.pass,validators));
                taskResult.ResultValues.Warn = sum(cellfun(@(v) v.warn,validators));
                taskResult.ResultValues.Fail = sum(cellfun(@(v) v.fail,validators));
                %% TODO: need to find all the escapes
                % that is the elements imported but not repoted
                % these are additional warnings
                %% check for nice
                if ~obj.nice && taskResult.ResultValues.Fail > 0
                    % not in nice mode and have failures
                    taskResult.Status = padv.TaskStatus.Fail;
                end
                %% print the results
                if obj.report
                    cellfun(@(v) v.report,validators);
                end
                %% go back to the process project
                % first restore the original path
                importedProject.close();
                path(originalPath);
                openProject(processProject.RootFolder);
                %% save important data
                outputFilePath = fullfile(obj.resolvePath(obj.OutputDirectory),...
                    outputFileName);
                save(outputFilePath,"validators","xmidb","elementDicitonary");
                if saveXMI
                    taskResult.OutputPaths = ...
                        [outputFilePath,xmiArtifactFilepath];
                else
                    taskResult.OutputPaths = outputFilePath;
                end
                %% back to starting location
                cd(startingPoint);
            catch ME
                disp(ME.message);
                disp(ME.getReport());
                for i = 1:numel(ME.stack)
                    disp(ME.stack(i));
                end
            end
        end

        function elements = findElemetsWithExternalUID(obj,element)
            % navigates through a system composer architecture and finds
            % all elements with externalID
            %
            %
            % check if element is an array if so deal with it
            if iscell(element)
                elements = cell(size(element));
                for i = 1:numel(elements)
                    elements{i} = ...
                        obj.findElemetsWithExternalUID(element{i});
                end
            elseif isscalar(element)
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
                % it's not a cell or a scalar, it's an array
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

