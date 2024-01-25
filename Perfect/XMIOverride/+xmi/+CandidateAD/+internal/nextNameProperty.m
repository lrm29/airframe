function nextName = nextNameProperty(objectArray, name)
    if isempty(objectArray)
        nextName = name;
    else
        existingNames = {objectArray.Name};
        nextName = xmi.CandidateAD.internal.nextName(existingNames, name);
    end
end