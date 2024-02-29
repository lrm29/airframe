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
            
            % need to find all the architectures (including activity
            % diagrams)
            importQuery = padv.builtin.query.FindModels;
            importedArtifacts = importQuery.run();
            foundInXMI = cell(size(importedArtifacts));
            notFoundInXMI = foundInXMI;
            for i = 1:numel(importedArtifacts)
                try 
                    model = systemcomposer.loadModel( ...
                        importedArtifacts(i).ArtifactAddress.getFileAddress());
                    % need to move back process project (hack to keep this file on
                    % path)
                    cd(processProject.RootFolder);
                    elements = obj.findElemetsWithExternalUID(model.Architecture);
                    tempFound = cell(size(elements));
                    tempNotFound = tempFound;
                    for j = 1:numel(elements)
                        try
                            xmidb.LookupTable(elements{j}.ExternalUID);
                            tempFound{j} = elements(j);
                            taskResult.ResultValues.Pass = 1 + ...
                                taskResult.ResultValues.Pass;
                        catch ME
                            if strcmp(ME.identifier,'MATLAB:Containers:Map:NoKey')
                                tempNotFound{j} = elements(j);
                                taskResult.ResultValues.Warn = 1 + ...
                                    taskResult.ResultValues.Warn;
                            else
                                taskResult.Status = padv.TaskStatus.Error;
                                warning(ME.message);
                                openProject(processProject.RootFolder);
                                processAdvisorWindow();
                                return;
                            end
                        end
                    end
                    tempFound = [tempFound{:}];
                    tempNotFound = [tempNotFound{:}];
                    foundInXMI{i} = tempFound;
                    notFoundInXMI{i} = tempNotFound;
                    % move back to keep things working
                    cd(importedProject.RootFolder);
                catch ME
                    warning(ME.message);
                end
            end

            % flatten element data
            foundInXMI = [foundInXMI{:}];
            notFoundInXMI = [notFoundInXMI{:}];
            % count the missing elements
            taskResult.ResultValues.Warn = taskResult.ResultValues.Warn + ...
                sum(~ismember(xmidb.LookupTable.keys, ...
                cellfun(@(x)x.ExternalUID,foundInXMI,'UniformOutput',false)));
            %% go back to the process project
            openProject(processProject.RootFolder);
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

