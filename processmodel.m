function processmodel(pm)
% Defines the project's processmodel

arguments
    pm padv.ProcessModel
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Include/Exclude Tasks in processmodel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define Shared Path Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set default root directory for task results
pm.DefaultOutputDirectory = fullfile('$PROJECTROOT$', 'PA_Results');
defaultResultPath = fullfile( ...
    '$DEFAULTOUTPUTDIR$','$ITERATIONARTIFACT$');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Register Tasks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xmlExclusions = ["Skyzer Contractor System Model",...
    "ProductSupportPackageConfig"];
triggerEnv = getenv("$CI_MERGE_REQUEST_ID");
runAll = getenv("RUNALL");
fprintf("Env value seen: %s\n",triggerEnv);
fprintf("Runall value seen: %s\n",runAll);
if isempty(triggerEnv) && isempty(runAll)
    xmiQuery = XMIImporterCI.query.findByExtension( ...
        exclusions= xmlExclusions,...
        extension=".xml",...
        inclusions="Skyzer Mission Model");
    mdzipQuery = XMIImporterCI.query.findByExtension(...
        extension=".mdzip",...
        inclusions=["KPDM Catapult Sample Model1 (updated_Jack)",...
        "CSRM","Skyzer Mission Model"]);
else
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
psptTask = pm.addTask(citools.task.PackagePSP( ...
    AccessToken="eupHXNYdZ6oouy2piVsP", pspDirectory="Perfect", ...
    Nice=true));

importMDZIPTask = pm.addTask(XMIImporterCI.task.ImportXMI(...
    IterationQuery=mdzipQuery,Name="Import MDZIP",...
    OutputDirectory=fullfile('$DEFAULTOUTPUTDIR$',"MDZIPImport"),...
    Nice=true)); % turn off nice when import is expected to pass


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set Task relationships
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
importTask.runsAfter(importMDZIPTask);
checkTask.dependsOn(importTask);
% make sure pspt is last
psptTask.dependsOn(importMDZIPTask); % replace when second check task is added
psptTask.dependsOn(checkTask);

% !PROCESSMODEL_EDITOR_MARKER! %
% Do not remove. Process Advisor uses the comment above to automatically add tasks. %

end