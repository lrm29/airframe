classdef PathManager < handle
    %PATHMANAGER Summary manages path when entering and exiting the main
    %project
    
    properties (SetAccess=protected)
        Project
        OldPath = string.empty
    end
    
    methods
        function pathMangerObj = PathManager()
            %PATHMANAGER Construct an instance of this class
            pathMangerObj.Project = currentProject();
        end

        leaveProject(this);
        reopenProject(this);
    end
end

