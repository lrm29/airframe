function rebuild_s_functions(show_progress_option)
    %rebuild_s_functions  Rebuild the S-Functions required by this project
    %
    %   Simple utility to rebuild the S-Functions required by this project.
    %   This is implemented as a function, not as a script, to avoid adding
    %   unwanted variables to the MATLAB base workspace.
    
    %   Copyright 2011-2018 The MathWorks, Inc.
    
    % Give the user an indication of progress:
    if nargin < 1
        show_progress = true;
    else
    show_progress = strcmp(show_progress_option, 'show_progress');
    end
    [progressFcn, closeFcn] = i_waitbar(show_progress);
    progressFcn(0, 'Building S-Functions...');
    
    % Use project API to get the current project:
    project = currentProject;
    projectRoot = project.RootFolder;
    % We keep the source files for this project in $projectroot/src:
    sourceFolder = fullfile(projectRoot, 'src');
    % We put the compiled binaries in the local "work" folder:
    outputFolder = fullfile(projectRoot, 'lib');
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder)
    end
    oldFolder = cd(sourceFolder);
    
    % Use onCleanup to ensure we cd back to the current folder:
    scopedCleanFuncion = onCleanup(@()cd(oldFolder));
    progressFcn(0.5, 'Building S-Functions...');
    
    try       
        % Since we have just one S-Function we can hard-code its name here.
        mex('timesthree.c', '-outdir', outputFolder);
    catch E
        % Something went wrong with compilation. Report to the user and stop.
        closeFcn();        
        if show_progress
            error('Failed to build S-Functions:\n%s', E.message);
        end
    end
    
    % Report success:
    progressFcn(1, 'Successfully built S-Functions');
    % Wait a little while for the user to read the completion message.
    pause(1.5)
    closeFcn();
end

function [progressFcn, closeFcn] = i_waitbar(show_progress)
    % Thin wrapper on waitbar
    if ~show_progress
        closeFcn = @()[];
        progressFcn = @(progress, message)[];
        return
    end   
    h = waitbar(0, '', 'name', 'Building S-Functions');    
    function closeWaitBar()
        if isvalid(h)
            close(h)
        end
    end
    function showProgress(progress, message)
        waitbar(progress, h, message);
    end
    closeFcn = @closeWaitBar;
    progressFcn = @showProgress;
end
