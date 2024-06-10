function PostPullFcn(pspBuilder)
    generateVersionCheck(pspBuilder);
end

function generateVersionCheck(pspBuilder)
    versionFile = fullfile(pspBuilder.ToolboxDir, "Src", "SupportedVersion.json");
    versionStruct = jsondecode(fileread(versionFile));

    fileContent = sprintf('function [release, update] = getCompatibleVersion\n');
    fileContent = sprintf('%s   release="%s";\n', fileContent, versionStruct.Release);
    fileContent = sprintf('%s   update="%i";\n', fileContent, versionStruct.Update);
    fileContent = sprintf('%send\n', fileContent);

    scriptFile = fullfile(pspBuilder.InternalDir, "+utils", "getCompatibleVersion.m");
    writelines(fileContent,scriptFile);
end