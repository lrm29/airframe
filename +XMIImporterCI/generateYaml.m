function generateYaml(options)
% generates Yaml file
arguments
    % so we can tune this later
    options.force = false
end
pipeline = padv.pipeline.GitLabOptions;
pipeline.Tags = "pilot";
pipeline.RerunFailedTasks = true;
pipeline.RerunErroredTasks = true;
pipeline.MatlabLaunchCmd = "mw -using BR2024ad matlab";
pipeline.MatlabStartupOptions = "-logfile output.log";
% force for now
options.ForceRunAllTasks = options.force;
padv.pipeline.generateGitLabPipeline(pipeline);
end