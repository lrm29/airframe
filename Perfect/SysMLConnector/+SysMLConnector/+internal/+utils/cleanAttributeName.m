function cleanName = cleanAttributeName(name)
    % Sanitize a string to be a proper xml attribute name.
    arguments
        name (1,:) char
    end

    cleanName = regexprep(name, '[^0-9a-zA-Z._-]', '_');
end