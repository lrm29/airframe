function reopenProject(this)
%REOPENPROJECT reopens project and restores old path
arguments
    this XMIImporterCI.utilities.PathManager
end
path(this.OldPath);
openProject(this.Project.RootFolder);
end

