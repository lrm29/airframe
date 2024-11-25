function processmodel(pm)
% Defines the project's processmodel

arguments
    pm padv.ProcessModel
end

%% setup flags
padv.internal.FeatureManager.set('PipelineParallelBranchMerger', true);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Include/Exclude Tasks in processmodel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

includePSPT = ispc() && isMATLABReleaseOlderThan("R2025a");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define Shared Path Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set default root directory for task results
pm.DefaultOutputDirectory = fullfile('$PROJECTROOT$', 'PA_Results');
defaultResultPath = fullfile( ...
    '$DEFAULTOUTPUTDIR$','$ITERATIONARTIFACT$'); %#ok<NASGU>

% All SLDDs are cached in a single cache file and that cache file is host
% machine-specific, not session-specific, so it must be set to a unique
% file in *each* MATLAB instance to prevent file contention. 
% This is only required on hosts with multiple concurrent runners.
jobID = getenv('CI_JOB_ID');
if ~isempty(jobID)
    startingCachePath = Simulink.dd.cachePath;
    [~, dictCacheName, dictCacheExt] = fileparts(startingCachePath);
    tempDictCachePath = fullfile(tempdir, 'CI_JOBS', jobID);
    mkdir(tempDictCachePath);
    Simulink.dd.setCachePath(fullfile(tempDictCachePath, [dictCacheName dictCacheExt]));
    writelines(sprintf('Simulink.dd.setCachePath(''%s'');', startingCachePath), fullfile(tempDictCachePath, 'finish.m'));
    addpath(tempDictCachePath);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Register Tasks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% setup queries
xmlExclusions = ["Skyzer Contractor System Model",...
    "ProductSupportPackageConfig"];
runAll = getenv("RUNALL");
tagged = getenv("CI_COMMIT_TAG");
fprintf("Runall value seen: %s\n",runAll);
fprintf("Trigger value seen: %s\n",tagged);
if isunix  
    disp("Runner super short test for linux")
    xmiQuery = XMIImporterCI.query.findByExtension( ...
        exclusions= xmlExclusions,...
        extension=".xml",...
        inclusions="EATestModel");
    mdzipQuery = XMIImporterCI.query.findByExtension(...
        extension=".mdzip",...
        inclusions="SysMLExampleModel");
elseif isempty(runAll)
    disp("Running shorten test set");
    xmiQuery = XMIImporterCI.query.findByExtension( ...
        exclusions= xmlExclusions,...
        extension=".xml",...
        inclusions=["Skyzer Mission Model", "EATestModel"]);
    mdzipQuery = XMIImporterCI.query.findByExtension(...
        extension=".mdzip",...
        inclusions=["KPDM Catapult Sample Model1 (updated_Jack)",...
        "CSRM","Skyzer Mission Model","SysMLExampleModel"]);
else
    disp("Running full test set");
    xmiQuery = XMIImporterCI.query.findByExtension( ...
        exclusions= [xmlExclusions,"Skyzer System Model"],...
        extension=".xml");
    mdzipQuery = XMIImporterCI.query.findByExtension(...
        extension=".mdzip");
end
%% setup the XMI tasks
importTask = pm.addTask(XMIImporterCI.task.ImportXMI( ...
    IterationQuery=xmiQuery));
checkTask = pm.addTask(XMIImporterCI.task.CheckXMIDB( ...
    IterationQuery=xmiQuery));
exportXMITask = pm.addTask(XMIImporterCI.task.ExportArchitecture( ...
    IterationQuery=xmiQuery));

%% setup the MDZip tasks
importMDZIPTask = pm.addTask(XMIImporterCI.task.ImportXMI(...
    IterationQuery=mdzipQuery,Name="Import MDZIP",...
    OutputDirectory=fullfile('$DEFAULTOUTPUTDIR$',"MDZIPImport")));
checkMDZIPTask = pm.addTask(XMIImporterCI.task.CheckXMIDB( ...
    IterationQuery=mdzipQuery,Name="Check MDZIP", ...
    OutputDirectory= ...
    fullfile('$DEFAULTOUTPUTDIR$',"MDZIPCheck","$ITERATIONARTIFACT$")));
exportMDZIPTask = pm.addTask(XMIImporterCI.task.ExportArchitecture( ...
    IterationQuery=mdzipQuery,Name="Export Architecture MDZIP",...
    OutputDirectory=fullfile("$DEFAULTOUTPUTDIR$","ExportArchitecturesMDZIP", ...
                    "$ITERATIONARTIFACT$")));

%% setup the PSPT task
if includePSPT
    if isempty(tagged)
        alwaysRun = false;
    else 
        disp("Forcing PSPT to run for tagged commit")
        alwaysRun = true;
    end
    psptTask = pm.addTask(citools.task.PackagePSP( ...
        AccessToken=string(getenv("PACKAGE_AUTH")), ...
        pspDirectory=fullfile("Perfect","SysMLConnector"), ...
        alwaysRun=alwaysRun));

    %% setup the upload tasks
    developmentNaming = XMIImporterCI.namingObjects.Development();
    if developmentNaming.isValid()
        % only if valid do we even need to think about this task
         developmentTask = pm.addTask(citools.task.UploadPackageToGit(...
             Name="Upload Development Package",...
            NamingObj=developmentNaming,...
            DependentTasks=psptTask));
    end
    
    stableReleaseNaming = XMIImporterCI.namingObjects.StableRelease();
    if stableReleaseNaming.isValid()
        % valid for release, create the task
        stableReleaseTask = pm.addTask(citools.task.UploadPackageToGit(...
            Name="Uploade Stable/Release Package",...
            NamingObj=stableReleaseNaming,DependentTasks=psptTask));
    end
end

%% setup the pipeline management
managePipelineTask = pm.addTask(citools.task.ManagePipelineConfiguration(...
        BaseYmlFile=citools.task.ManagePipelineConfiguration.BaseYmlFile(...
        citools.query.FindArtifactWithAddress( ...
        Path=fullfile(string(fileparts(mfilename("fullpath"))),"base.yml")),...
        Variables=[citools.task.ManagePipelineConfiguration.Variable(...
        Name="MATLAB_VERSION",Values=XMIImporterCI.utilities.getCIVersions(),...
        InputDependencyQueries=citools.query.FindArtifactWithAddress(...
        Path=fullfile("+XMIImporterCI","+utilities","getCIVersions.m"))),...
        citools.task.ManagePipelineConfiguration.Variable(...
        Name="TAGS",Values=["long-jobs","mmcbroom-linux"],JobNames=["","Linux"])]),...
        InitialYMLQuery=citools.query.FindArtifactWithAddress(...
        Path=fullfile(string(fileparts(mfilename("fullpath"))),"init.yml"))));

%% setup compare
compareMDZIPTask = pm.addTask(XMIImporterCI.task.CompareTextFiles(...
    Name="Compare MDZIP",...
    InputQuery1=padv.builtin.query.GetOutputsOfDependentTask(Task=exportMDZIPTask.Name),...
    InputQuery2=padv.builtin.query.GetOutputsOfDependentTask(Task=exportMDZIPTask.Name),...
    IterationQuery=mdzipQuery));
compareXMITask = pm.addTask(XMIImporterCI.task.CompareTextFiles(...
    Name="Compare XMI",...
    InputQuery1=padv.builtin.query.GetOutputsOfDependentTask(Task=exportXMITask.Name),...
    InputQuery2=padv.builtin.query.GetOutputsOfDependentTask(Task=exportXMITask.Name),...
    IterationQuery=xmiQuery));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set Task relationships
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
importTask.runsAfter(importMDZIPTask);
checkTask.dependsOn(importTask);
addInputQueries(checkTask, ...
    padv.builtin.query.GetOutputsOfDependentTask(Task=importTask.Name));
exportXMITask.dependsOn(importTask);
addInputQueries(exportXMITask, ...
    padv.builtin.query.GetOutputsOfDependentTask(Task=importTask.Name));
checkMDZIPTask.dependsOn(importMDZIPTask);
addInputQueries(checkMDZIPTask, ...
    padv.builtin.query.GetOutputsOfDependentTask(Task=importMDZIPTask.Name));
exportMDZIPTask.dependsOn(importMDZIPTask);
addInputQueries(exportMDZIPTask, ...
    padv.builtin.query.GetOutputsOfDependentTask(Task=importMDZIPTask.Name));
% make sure pspt is last
if includePSPT && isempty(getenv("DEVMODE"))
    importTask.dependsOn(psptTask); % replace when second check task is added
    importMDZIPTask.dependsOn(psptTask);
    psptTask.dependsOn(managePipelineTask);
elseif isempty(getenv("DEVMODE"))
    % if not dev mode but no pspt make import depend on manage
    importTask.dependsOn(managePipelineTask);
    importMDZIPTask.dependsOn(managePipelineTask);
end

if includePSPT
    if developmentNaming.isValid
        importTask.runsAfter(developmentTask);
        importMDZIPTask.runsAfter(developmentTask);
    end
    if stableReleaseNaming.isValid()
        stableReleaseTask.dependsOn([importMDZIPTask,importTask,checkTask, ...
            checkMDZIPTask,exportXMITask,exportMDZIPTask]);
    end
end

compareMDZIPTask.dependsOn(exportMDZIPTask);
compareXMITask.dependsOn(exportXMITask);

% !PROCESSMODEL_EDITOR_MARKER! %
% Do not remove. Process Advisor uses the comment above to automatically add tasks. %

end