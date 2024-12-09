function reopenProject(this)
%REOPENPROJECT reopens project and restores old path
arguments
    this XMIImporterCI.utilities.PathManager
end
%% first clean up
this.cleanup();
%% reopen the root project
path(this.OldPath);
openProject(this.Project.RootFolder);
end

