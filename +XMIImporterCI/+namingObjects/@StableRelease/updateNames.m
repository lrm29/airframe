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
    end
end
end