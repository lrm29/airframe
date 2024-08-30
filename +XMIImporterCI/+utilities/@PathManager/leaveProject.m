function leaveProject(this)
%LEAVEPROJECT leaves the project and updates the path to keep the PSP on it
arguments
    this XMIImporterCI.utilities.PathManager
end
close(this.Project);
this.OldPath = addpath(...
    [genpath(strjoin([this.Project.RootFolder,"Perfect"],filesep)),...
    genpath(this.Project.RootFolder)]);
end

