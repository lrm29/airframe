function generateYaml(options)
% generates Yaml file
arguments
    % so we can tune this later
    options.force = false
end
%% call to generate pipeline
pipeline = citools.utilities.generateYaml(force=options.force,Tags=getenv("TAGS"));
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
        ...%sprintf('      variables:'),sprintf('        RUNALL: "yes"'),...
        sprintf('    - if: ''$CI_PIPELINE_SOURCE != "merge_request_event"''')};%,...
        %sprintf('      variables:'),sprintf('        RUNALL: ""')};
    lines = [newLines,lines];
    %% save to file
    text = strjoin(lines,newline);
    fid = fopen(ymlFilePath,"W");
    fwrite(fid,text);
    fclose(fid);
end
end