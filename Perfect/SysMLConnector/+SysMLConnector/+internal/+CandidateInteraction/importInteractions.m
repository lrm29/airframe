function [candidateInteractions, umlInteractions] = importInteractions(xmiFileName, options)
    arguments
        xmiFileName (1,:) char
        options.BuildOne = false;
    end

    f = M3I.XmiReaderFactory();
    s = M3I.XmiReaderSettings;
    s.InputFormat = "MagicDraw";
    s.InLineProfiles = true;
    s.ProcessTopLevelSettings=true;
    s.UseCurrentXMIUri = true;
    s.FlattenProfiles = true;
    rdr = f.createXmiReader(s);
    m3imod = rdr.read(xmiFileName);
    mod = m3imod.content.at(1);
    
    umlInteractions = findInteractions(mod, [], []);
    numInteractions = numel(umlInteractions);
    candidateInteractions = SysMLConnector.internal.CandidateInteraction.Interaction.empty(0, numInteractions);

    if options.BuildOne
        % Only build the first interaction for debug purposes
        numInteractions = min(numInteractions, 1);
    end

    for interactionIdx = 1:numInteractions
        candidateInteractions(interactionIdx) = SysMLConnector.internal.CandidateInteraction.buildCandidateInteraction(umlInteractions(interactionIdx));
    end
end

function [interactions, visitedElements] = findInteractions(element, visitedElements, interactions)
    if isempty(visitedElements)
        visitedElements = containers.Map;
    end    
    elementID = element.toString;

    if isKey(visitedElements, elementID)
        return;
    end

    visitedElements(element.toString) = element;

    if isa(element, 'umlmm.Interaction')
        interactions = [interactions element];
    end

    propertyNames = ["packagedElement" "ownedBehavior"];

    for propertyIdx = 1:numel(propertyNames)
        propertyName = propertyNames(propertyIdx);

        try
            propertyValues = element.(propertyName);
        catch ME
            continue;
        end
        if isa(propertyValues, 'umlmm.SequenceOfPackageableElement')
            for propertyValueIdx = 1:propertyValues.size
                propertyValue = propertyValues.at(propertyValueIdx);
                [interactions, visitedElements] = findInteractions(propertyValue, visitedElements, interactions);            
            end
        else
            for propertyValueIdx = 1:numel(propertyValues)
                propertyValue = propertyValues(propertyValueIdx);
                [interactions, visitedElements] = findInteractions(propertyValue, visitedElements, interactions);            
            end
        end
    end
end
