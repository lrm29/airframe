function cleanupTempDirectory(startDirectory, tempDirectory)
    % go to the start directory then delete the temp directory.
    cd(startDirectory);
    rmdir(tempDirectory, 's');
end