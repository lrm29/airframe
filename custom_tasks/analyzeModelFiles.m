function result = analyzeModelFiles(file)
%analyzeModelFiles  Project custom task to analyze Simulink files
%
% Input arguments:
%  file - string - The absolute path to a file included in the custom task.
%  When you run the custom task, project provides the file 
%  input for each selected file.
%
% Output arguments:
%  result - string - The result displays the number of blocks in the model.
%  The project displays the result in the Custom Task Results 
%  column.

%   Copyright 2016-2020 The MathWorks, Inc.

project = currentProject;
projectFile = findFile(project, file);
[~, name, ext] = fileparts(projectFile.Path);
if ismember(ext, {'.mdl','.slx'})
    try
        [~, blockCounts] = sldiagnostics(name, 'CountBlocks');
        result = sprintf('Block Count: %d', blockCounts(1).count);
    catch exception
        warning(exception.identifier, "%s", exception.message);
        result = 'Failed to analyze file.';
    end
else
    result = [];
end

end
