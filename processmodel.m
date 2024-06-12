function processmodel(pm)
% Defines the project's processmodel

arguments
    pm padv.ProcessModel
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Include/Exclude Tasks in processmodel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

includePSPT = ispc();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define Shared Path Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set default root directory for task results
pm.DefaultOutputDirectory = fullfile('$PROJECTROOT$', 'PA_Results');
defaultResultPath = fullfile( ...
    '$DEFAULTOUTPUTDIR$','$ITERATIONARTIFACT$'); %#ok<NASGU>

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Register Tasks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xmlExclusions = ["Skyzer Contractor System Model",...
    "ProductSupportPackageConfig"];
runAll = getenv("RUNALL");
fprintf("Runall value seen: %s\n",runAll);
if isempty(runAll)
    disp("Running shorten test set");
    xmiQuery = XMIImporterCI.query.findByExtension( ...
        exclusions= xmlExclusions,...
        extension=".xml",...
        inclusions="Skyzer Mission Model");
    mdzipQuery = XMIImporterCI.query.findByExtension(...
        extension=".mdzip",...
        inclusions=["KPDM Catapult Sample Model1 (updated_Jack)",...
        "CSRM","Skyzer Mission Model"]);
else
    disp("Running full test set");
    xmiQuery = XMIImporterCI.query.findByExtension( ...
        exclusions= xmlExclusions,...
        extension=".xml");
    mdzipQuery = XMIImporterCI.query.findByExtension(...
        extension=".mdzip");
end
importTask = pm.addTask(XMIImporterCI.task.ImportXMI( ...
    IterationQuery=xmiQuery));
checkTask = pm.addTask(XMIImporterCI.task.CheckXMIDB( ...
    IterationQuery=xmiQuery,Nice=true));
fprintf("Trigger value seen: %s\n",getenv("CI_COMMIT_TAG"));
if includePSPT
    if isempty(getenv("CI_COMMIT_TAG"))
        alwaysRun = false;
    else 
        disp("Forcing PSPT to run for tagged commit")
        alwaysRun = true;
    end
    psptTask = pm.addTask(citools.task.PackagePSP( ...
        AccessToken="eupHXNYdZ6oouy2piVsP", ...
        pspDirectory=fullfile("Perfect","SysMLConnector"), ...
        alwaysRun=alwaysRun));
end

importMDZIPTask = pm.addTask(XMIImporterCI.task.ImportXMI(...
    IterationQuery=mdzipQuery,Name="Import MDZIP",...
    OutputDirectory=fullfile('$DEFAULTOUTPUTDIR$',"MDZIPImport")));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set Task relationships
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
importTask.runsAfter(importMDZIPTask);
checkTask.dependsOn(importTask);
% make sure pspt is last
if includePSPT
    psptTask.dependsOn(importMDZIPTask); % replace when second check task is added
    psptTask.dependsOn(checkTask);
end

% !PROCESSMODEL_EDITOR_MARKER! %
% Do not remove. Process Advisor uses the comment above to automatically add tasks. %

end