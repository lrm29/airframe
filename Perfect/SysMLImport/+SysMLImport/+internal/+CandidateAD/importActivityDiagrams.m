function importActivityDiagrams(xmiFileName)
    [packagedActivities, activityStructs] = ADBuilder.getActivities(xmiFileName);
    numActivities = numel(packagedActivities);

    startDir = pwd;
    cleanupStartDir = onCleanup(@() cd(startDir));

    startPath = path;
    cleanupPath = onCleanup(@() path(startPath));

    caughtErrors = cell(0, numActivities);
    errorIndex = 1;

    [~, fileName] = fileparts(xmiFileName);

    if ~isfolder(fileName)
        mkdir(fileName);
    end

    cd(fileName);
    addpath(pwd);

    topModelName = matlab.lang.makeValidName(fileName);
    archModel = systemcomposer.createModel(topModelName);
    architecture = archModel.Architecture;
    save(archModel);
    cleanupModel = onCleanup(@() open_system(topModelName));

    activitiesFolder = 'Activities';
    if ~isfolder(activitiesFolder)
        mkdir(activitiesFolder);
    end

    cd(activitiesFolder);
    addpath(pwd);

    for activityIdx = 1:numActivities
        try
            activityStruct = activityStructs{activityIdx};
            
            % Convert the XMI structure to a candidate activity diagram.
            ad = ADBuilder.buildCandidateAD(activityStruct);

            % Publish the candidate diagram as a real diagram.
            try
                publish(ad);
                modelName = ad.ZCElement.Name;
            catch ME
                try %#ok<TRYNC> try to close the errant model if possible.
                    modelName = ad.ZCElement.Name;
                    save_system(modelName, SaveDirtyReferencedModels='on');
                    close_system(modelName);
                end
                rethrow(ME);
            end
            save_system(modelName, SaveDirtyReferencedModels='on');
            close_system(modelName);

            % Create a component in the package model
            activityComponent = ADBuilder.internal.addComponentTree(architecture, activityStruct);

            % Link the component in the package model to the activity.
            try
                behaviorComponent = addComponent(activityComponent.Architecture, 'OwnedBehavior');
                linkToModel(behaviorComponent, modelName);
            catch ME
                if ~strcmp(ME.identifier, 'MATLAB:assertion:failed')
                    rethrow(ME);
                end
            end
        catch ME
            if ismissing(packagedActivities(activityIdx))
                caughtError.Activity = '<missing>';
            else
                caughtError.Activity = packagedActivities{activityIdx};
            end
            caughtError.Exception = ME;
            caughtErrors{errorIndex} = caughtError;
            errorIndex = errorIndex + 1;
        end
    end

    Simulink.BlockDiagram.arrangeSystem(topModelName);
    save_system(topModelName, SaveDirtyReferencedModels='on');

    cd(startDir);

    [~, xmiFileName] = fileparts(xmiFileName);
    fileID = fopen([xmiFileName '_ErrorLog.html'], 'w');
    fileCleanup = onCleanup(@() fclose(fileID));
    fprintf(fileID, '<html>\n\t<body>\n');
    if ~isempty(caughtErrors)
        for errorIdx = 1:errorIndex-1
            report = getReport(caughtErrors{errorIdx}.Exception);
            report = strrep(report, newline, ['<br>' newline]);
            fprintf(fileID, '<b>%s</b><br>\n<b><i>%s</i></b><br>\n%s<br><br><br>\n', caughtErrors{errorIdx}.Activity, caughtErrors{errorIdx}.Exception.identifier, report);
        end
    else
        fprintf(fileID, 'No errors detected during import.\n');
    end
    fprintf(fileID, '\t</body>\n</html>\n');
end