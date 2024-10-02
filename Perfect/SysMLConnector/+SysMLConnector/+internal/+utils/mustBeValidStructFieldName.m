function mustBeValidStructFieldName(name)
    % Mitigate keyword triggers.
    if ~iskeyword(name)
        mustBeValidVariableName(name);
    end
end