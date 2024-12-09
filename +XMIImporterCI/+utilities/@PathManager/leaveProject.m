function leaveProject(this)
%LEAVEPROJECT leaves the project and updates the path to keep the PSP on it
arguments
    this XMIImporterCI.utilities.PathManager
end
%% first clean up 
this.cleanup();
%% leave the project
projectPath = this.Project.ProjectPath;
close(this.Project);
this.OldPath = path;
arrayfun(@(f) addpath(f.File),projectPath);
end

