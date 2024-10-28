function updateNames(this,artifacts)
%UPDATENAMES adds version number if needed
arguments
    this XMIImporterCI.namingObjects.StableRelease
    artifacts padv.Artifact
end
if this.IncludeVersion
    toolboxInfo = ...
        citools.task.UploadPackageToGit.DefaultNaming.findToolboxInfo(artifacts);
    if ~isempty(toolboxInfo)
        this.PackageVersion = this.PackageVersion+this.Delemiter+...
            toolboxInfo.Version;
    else
        warning("XMIImporterCI:namingObjects:StableRelease:NoToolbox", ...
            "No toolbox json file was found in the artifacts provided, "+...
            "so file will be uploaded to version %s.",this.PackageVersion);
    end
end
end