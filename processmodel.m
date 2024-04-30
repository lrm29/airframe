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
    exclusionQuery = XMIImporterCI.query.findByExtension( ...
        exclusions= ...
        ["Skyzer Contractor System Model","ProductSupportPackageConfig"],...
        extension=".xml");
    importTask = pm.addTask(XMIImporterCI.task.ImportXMI( ...
        IterationQuery=exclusionQuery));
    checkTask = pm.addTask(XMIImporterCI.task.CheckXMIDB( ...
        IterationQuery=exclusionQuery,Nice=true));
    psptTask = pm.addTask(citools.task.PackagePSP( ...
        AccessToken="eupHXNYdZ6oouy2piVsP", pspDirectory="Perfect", ...
        Nice=true));

    importMDZIPTask = pm.addTask(XMIImporterCI.task.ImportXMI(...
        IterationQuery= XMIImporterCI.query.findByExtension(...
        extension=".mdzip"),Name="Import MDZIP",...
        OutputDirectory=fullfile('$DEFAULTOUTPUTDIR$',"MDZIPImport")));
   

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Set Task relationships
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    importTask.runsAfter(importMDZIPTask);
    checkTask.dependsOn(importTask);
    psptTask.dependsOn(checkTask);

    % !PROCESSMODEL_EDITOR_MARKER! %
    % Do not remove. Process Advisor uses the comment above to automatically add tasks. %

end