function generateYaml(options)
% generates Yaml file
arguments
    % so we can tune this later
    options.force = false
end
pipeline = padv.pipeline.GitLabOptions;
pipeline.Tags = "long-jobs";
pipeline.RerunFailedTasks = true;
pipeline.RerunErroredTasks = true;
releaseInfo = matlabRelease;
pipeline.MatlabLaunchCmd = "mw -using B"+releaseInfo.Release+"d matlab";
pipeline.MatlabStartupOptions = "-logfile output.log";
% force for now
pipeline.ForceRunAllTasks = options.force;
padv.pipeline.generateGitLabPipeline(pipeline);

%% need to add wokrflow info
files = dir(pipeline.GeneratedPipelineDirectory);
files = files(~[files.isdir]);
for i = 1:numel(files)
    ymlFilePath = strjoin({files(i).folder,files(i).name},filesep);
    text = fileread(ymlFilePath);
    lines = strsplit(text,"\n",CollapseDelimiters=false);
    %% add workflow to the yaml
    newLines = {'workflow:',sprintf('  rules:'),...
        sprintf('    - if: ''$CI_PIPELINE_SOURCE == "merge_request_event"'''),...
        sprintf('      variables:'),sprintf('        RUNALL: "yes"'),...
        sprintf('    - if: ''$CI_PIPELINE_SOURCE != "merge_request_event"'''),...
        sprintf('      variables:'),sprintf('        RUNALL: ""')};
    lines = [newLines,lines];
    %% save to file
    text = strjoin(lines,newline);
    fid = fopen(ymlFilePath,"W");
    fwrite(fid,text);
    fclose(fid);
end
end