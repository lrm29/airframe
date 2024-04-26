function nextNameString = nextName(existingNames, startString)
    % Return the next name in the sequence based on the max trailing digit
    % found.
    %
    % for example where inputArray is an array of names {'pin1', 'pin', 'pin7'}:
    %   >> nextNameString = SysMLConnector.internal.utils.nextName(inputArray, 'pin');
    %
    %      nextNameString = 'pin8'
    %
    %   >>
    %
    pattern = sprintf('^%s(?<MaxDigit>\\d*)$', startString);
    
    nameMatches = regexp(existingNames, pattern, 'names');
        
    exactMatch = any(strcmp(existingNames, startString));

    if exactMatch
        maxDigit = 1;
    else
        maxDigit = 0;
    end
    
    for matchIdx = 1:numel(nameMatches)
        match = nameMatches{matchIdx};
        if ~isempty(match) && isfield(match, 'MaxDigit') && ~isempty(match.MaxDigit)
            maxDigit = max(str2double(match.MaxDigit), maxDigit);
        end
    end

    if isequal(maxDigit, 0)
        idxStr = '';
    else
        idxStr = num2str(maxDigit + 1);
    end

    nextNameString = sprintf('%s%s', startString, idxStr);
end