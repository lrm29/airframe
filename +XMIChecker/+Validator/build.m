function obj = build(candidate,xmidb,foundElements)
%BUILD builds validators of the correct type
% uses candidate type to build validators
arguments
    candidate 
    xmidb SysMLImport.internal.CandidateAD.internal.XMIDatabase
    foundElements dictionary
end
if iscell(candidate)
    % cell array of mixed or same type
    obj = cellfun( ...
        @(c) XMIChecker.Validator.build(c,xmidb,foundElements), ...
        candidate,UniformOutput=false);
elseif isscalar(candidate)
    % determine class name of the candidate
    [~,~,classname] = fileparts(class(candidate));
    classname = extractAfter(string(classname),".");
    % find if there is a validator
    if exist("XMIChecker.Validator."+classname,"class") == 8
        obj = XMIChecker.Validator.(classname)(...
            candidate,xmidb,foundElements);
    else
        % don't have a specific validator for this yet
        obj = XMIChecker.Validator.Default(...
            candidate,xmidb,foundElements);
    end
else
    % assume array of like type
    obj = arrayfun(...
        @(c) XMIChecker.Validator.build(c,xmidb,foundElements), ...
        candidate);
end
end

