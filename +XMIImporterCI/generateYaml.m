options = padv.pipeline.GitLabOptions;
options.Tags = "pilot";
options.RerunFailedTasks = true;
options.RerunErroredTasks = true;
options.MatlabLaunchCmd = "mw -using BR2024ad matlab";
options.MatlabStartupOptions = "-logfile output.log";
padv.pipeline.generateGitLabPipeline(options);