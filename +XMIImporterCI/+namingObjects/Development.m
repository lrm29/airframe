classdef Development < citools.task.UploadPackageToGit.NamingInterface
    %DEVELOPMENT provides naming for the development packag

    properties (SetAccess=protected)
        ServerURL string = extractAfter(string(getenv("CI_API_V4_URL")), ...
            'https://')
        AuthenticationToken string = string(getenv("PACKAGE_AUTH"))
        ProjectID string = string(getenv("CI_PROJECT_ID"))
        PackageVersion string = "Latest"
        PackageName string = "Development"
    end

    methods
        function developmentObj = Development()
            %DEVELOPMENT Construct an instance of this class
        end
    end
end