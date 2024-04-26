function modelFilePath = getModelFile(mdzipFile, outputDirectory)
    %% GETMODELFILE - Extract the shared model file from an mdzip archive and name it to the archive name to be used for import.
    %
    %
    arguments
        mdzipFile (1,1) string {mustBeFile}
        outputDirectory (1,1) string {mustBeFolder} = fileparts(which(mdzipFile))
    end

    [~, modelName] = fileparts(which(mdzipFile));
    modelFilePath = fullfile(outputDirectory, modelName + ".xml");

    assert(~isfile(modelFilePath), 'SysMLConnector:internal:utils:getModelFile:FileExists', 'File ''%s'' already exists. Delete it then try again.', modelFilePath);

    zipHandle = java.io.File(mdzipFile);
    zipFile = org.apache.tools.zip.ZipFile(zipHandle);
    cleanupZipFile = onCleanup(@() zipFile.close());

    % Check for a shared model first.
    modelFilename = 'com.nomagic.magicdraw.uml_model.shared_model';
    modelEntry = zipFile.getEntry(modelFilename);

    if isempty(modelEntry)
        % If no shared model, check for a general model.
        modelFilename = 'com.nomagic.magicdraw.uml_model.model';
        modelEntry = zipFile.getEntry(modelFilename);
    end

    assert(~isempty(modelEntry), 'SysMLConnector:internal:utils:getModelFile:FileNotFound', 'Unable to find model file ''%s'' in archive ''%s''.', modelFilename, mdzipFile);
    
    inputstream = zipFile.getInputStream(modelEntry);

    outputFileHandle = java.io.File(modelFilePath);
    outputStream = java.io.FileOutputStream(outputFileHandle);
    cleanupStream = onCleanup(@() outputStream.close());

    org.apache.commons.io.IOUtils.copy(inputstream, outputStream);  

    assert(isfile(modelFilePath), 'SysMLConnector:internal:utils:getModelFile:UnexpectedError', 'An unexpected error occurred when trying to process model ''%s''.', mdzipFile);

    % <ProductSupportPackage><Protect/></ProductSupportPackage>
end