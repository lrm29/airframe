function appendToDescription(simulinkHandle,text)
%APPENDTODESCRIPTION adds the text to the description of the Simulink
%handle
arguments
    simulinkHandle double {mustBeNonempty}
    text {mustBeText}
end
existingDescription = get_param(simulinkHandle,"Description");
if isempty(existingDescription)
    description = text;
else
    description = strjoin([string(existingDescription),text]," ");
end
set_param(simulinkHandle,"Description",description);
end

