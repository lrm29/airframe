function result = billOfMaterials(file)
%billOfMaterials   Project custom task for generating a "bill of
%materials" report. This report includes an MD5 checksum for each file in
%the project, together with revision information.
%
% Input arguments:
%  file - string - The absolute path to a file included in the custom task.
%  When you run the custom task, project provides the file 
%  input for each selected file.
%
% Output arguments:
%  result - string - Information about the file for inclusion in the 
%  report. The project displays the result in the Custom Task 
%  Results column.

%   Copyright 2016-2018 The MathWorks, Inc.

project = currentProject;
projectFile = project.findFile(file);

result = ...
    "MD5 Checksum: " + Simulink.getFileChecksum(file) + newline + ...
    "Source control status: " + char(projectFile.SourceControlStatus) + newline +  ...
    "Revision: " + projectFile.Revision + newline;

end
