function nextName = nextNameProperty(objectArray, name)
    if isempty(objectArray)
        nextName = name;
    else
        existingNames = {objectArray.Name};
        nextName = SysMLConnector.internal.utils.nextName(existingNames, name);
    end
end