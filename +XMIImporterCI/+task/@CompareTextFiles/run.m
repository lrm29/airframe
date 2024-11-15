function taskResult = run(this,inputArtifacts)
%RUN runs the task
arguments
    this XMIImporterCI.task.CompareTextFiles
    inputArtifacts (1,2) cell
end
taskResult = padv.TaskResult;
% validate input
assert(all(size(inputArtifacts{1}) == size(inputArtifacts{2})), ...
    "XMIImporterCI:task:CompareTextFiles:InvalidInput", ...
    "Input queries returned different numbers of files %d for 1 %d for 2, cannot compare without matching numbers of files",...
    numel(inputArtifacts{1}),numel(inputArtifacts{2}));
% now for the comparing
for i = 1:numel(inputArtifacts{1})
    comparison = XMIImporterCI.utilities.LineComparison(...
        string(fileread(inputArtifacts{1}(i).ArtifactAddress.getAbsolutePath)),...
        string(fileread(inputArtifacts{2}(i).ArtifactAddress.getAbsolutePath)));
    if comparison.Identical
        taskResult.ResultValues.Pass = taskResult.ResultValues.Pass + 1;
        fprintf("Files %s and %s are identical\n", ...
            inputArtifacts{1}(i).ArtifactAddress.getAbsolutePath, ...
            inputArtifacts{2}(i).ArtifactAddress.getAbsolutePath);
    else
        comparison.print();
        taskResult.ResultValues.Fail = taskResult.ResultValues.Fail + 1;
    end
end
% decide on failure
if ~this.NiceMode && taskResult.ResultValues.Fail > 0
    taskResult.Status = "Fail";
end
end