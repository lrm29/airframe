function [candidateInteraction, notImported] = buildCandidateInteraction(element)
    notImported = [];
    candidateInteraction = SysMLConnector.internal.CandidateInteraction.Interaction(element.name, SysMLConnector.internal.utils.getExtID(element), []);

    for lifelineIdx = 1:element.lifeline.size
        umlLifeline = element.lifeline.at(lifelineIdx);

        umlLifelineNameIdx = 1;
        umlLifelineNameParts = {};

        if ~isempty(umlLifeline.name)
            umlLifelineNameParts{umlLifelineNameIdx} = umlLifeline.name; %#ok<AGROW>
            umlLifelineNameIdx = umlLifelineNameIdx + 1;
        end
        
        % Reference ID should be the represents.type but if it was not
        % defined in the SysML model, then settle for whatever is
        % available.
        referenceID = [];
        if ~isempty(umlLifeline.represents)
            referenceID = SysMLConnector.internal.utils.getExtID(umlLifeline.represents);

            if ~isempty(umlLifeline.represents.name)
                umlLifelineNameParts{umlLifelineNameIdx} = umlLifeline.represents.name; %#ok<AGROW>
                umlLifelineNameIdx = umlLifelineNameIdx + 1;
            end

            if ~isempty(umlLifeline.represents.type)
                referenceID = SysMLConnector.internal.utils.getExtID(umlLifeline.represents.type);

                if ~isempty(umlLifeline.represents.type.name)
                    umlLifelineNameParts{umlLifelineNameIdx} = umlLifeline.represents.type.name; %#ok<AGROW>
                    umlLifelineNameIdx = umlLifelineNameIdx + 1; %#ok<NASGU>
                end
            end
        end

        umlLifelineName = strtrim(strjoin(umlLifelineNameParts, ' '));

        lifelineID = SysMLConnector.internal.utils.getExtID(umlLifeline);
        
        addLifeline(candidateInteraction, umlLifelineName, lifelineID, referenceID);
    end

    %% Collect Fragment Data
    if ~isMATLABReleaseOlderThan("R2024b")
        % only check fragments in R2024b and later
        for fragmentIdx = 1:element.fragment.size
            umlFragment = element.fragment.at(fragmentIdx);
            candidateInteraction.addFragment(umlFragment);
        end
        % add the not imported to the output
        if ~isempty(candidateInteraction.Fragments)
            notImported = [notImported, candidateInteraction.Fragments.NotImported];
        end
    end
end

