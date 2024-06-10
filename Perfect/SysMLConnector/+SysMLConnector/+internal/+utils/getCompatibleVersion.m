% This is a stub for a file that is auto-generated during the build process.
% If this file survives the build, something went wrong. 
function [release, update] = getCompatibleVersion
    currentVersion = matlabRelease;

    release = currentVersion.Release;
    update  = currentVersion.Update;

    % For warning testing.
    update = update + 1;
end