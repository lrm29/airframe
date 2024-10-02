function parseLog(logFile)
    fid = fopen(logFile);
    fClose = onCleanup(@() fclose(fid));
    
    warnOn=false;
    printRunnerInfo=true;
    while ~feof(fid)
        line = fgetl(fid);
        
        printLine = false;
        if printRunnerInfo && startsWith(line, {'Running on', 'Version:', 'Git revision:', 'Git branch:', 'GO version:', 'Built:', 'OS/Arch:'})
            printLine = true;

            if startsWith(line, 'OS/Arch')
                printRunnerInfo = false;
            end
        end

        if startsWith(line, 'MATLAB Version:')
            printLine = true;
        end

        if startsWith(line, '## Starting Process')
            while ~startsWith(line, '######')
                fprintf('%s\n', line);
                line = fgetl(fid);
            end
        end

        if startsWith(line, '## Starting task')
            printLine = true;
        end

        % PSPT Task
        if startsWith(line, {'Data:', '            Count','            _____', '    Pass','    Fail','    Warn'})
            printLine = true;
        end

        % Import Task
        if startsWith(line, '#### Output Artifacts:')
            while ~startsWith(line, '######')
                fprintf('%s\n', line);
                line = fgetl(fid);
            end
        end

        if warnOn 
            if startsWith(line, '[Warning:')
                while ~endsWith(line, '] ')
                    fprintf('%s\n', line);
                    line = fgetl(fid);
                end
                fprintf('%s\n', line);
            elseif startsWith(line, 'ERROR:')
                printLine=true;
            elseif startsWith(line, 'Error:')
                while ~startsWith(line, '###')
                    fprintf('%s\n', line);
                    line = fgetl(fid);
                end
            end
        end

        if startsWith(line, '***Importing file')
            warnOn = true;
            printLine=true;
        end

        if startsWith(line, '***Import complete')
            warnOn = false;
            printLine=true;
        end

        if printLine
            fprintf('%s\n', line);
        end
        
        if feof(fid)
            % Print the last line
            fprintf('%s\n', line);
        end
    end
end