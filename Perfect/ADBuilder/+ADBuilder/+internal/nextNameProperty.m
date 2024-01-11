function nextName = nextNameProperty(objectArray, name)
    if isempty(objectArray)
        nextName = name;
    else
        existingNames = {objectArray.Name};
        nextName = ADBuilder.internal.nextName(existingNames, name);
    end
end