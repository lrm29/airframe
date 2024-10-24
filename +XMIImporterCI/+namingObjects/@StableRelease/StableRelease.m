classdef StableRelease < citools.task.UploadPackageToGit.NamingInterface
    %STABLERELEASE naming for stable and release options

    properties (SetAccess=protected)
        ServerURL string = extractAfter(string(getenv("CI_API_V4_URL")), ...
            'https://')
        TagName string = string(getenv("CI_COMMIT_TAG"))
        AuthenticationToken string = string(getenv("PACKAGE_AUTH"))
        ProjectID string = string(getenv("CI_PROJECT_ID"))
        PackageVersion string = "Latest"
        PackageName string = "Stable"
        Branch string
        IncludeVersion = false;
    end

    properties (Constant)
        Delemiter = "-"
    end

    methods
        function stableReleaseObj = StableRelease()
            %STABLERELEASE Construct an instance of this class
            if ~(isempty(stableReleaseObj.TagName) || ...
                    ismissing(stableReleaseObj.TagName) || ...
                    strcmp(stableReleaseObj.TagName,""))
                % this is expected to be a release
                stableReleaseObj.PackageName = "Release";
                stableReleaseObj.PackageVersion = stableReleaseObj.TagName;
                stableReleaseObj.IncludeVersion = true;
            elseif strcmp(getenv("CI_COMMIT_REF_PROTECTED"), ...
                    "true")
                % protected branch so change the version to the branch name
                % and set the package name to Stable
                branch = string(getenv("CI_COMMIT_BRANCH"));
                if isempty(branch) || ...
                        strcmp(branch,"")
                    % maybe this is a merge request
                    branch = string( ...
                        getenv("CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"));
                end
                if ~(isempty(branch) || ismissing(branch) || strcmp(branch,""))
                    % have an actual branch name
                    stableReleaseObj.PackageVersion = branch;
                else
                    warning("XMIImporterCI:namingObjects:StableRelease:NoBranch",...
                        "Branch could not be determined, defaulting to %s for version",...
                        stableReleaseObj.PackageVersion);
                end
            else
                % Not a tagged commit (Release) or a protected branch
                % use the default names
            end
        end
    end
end