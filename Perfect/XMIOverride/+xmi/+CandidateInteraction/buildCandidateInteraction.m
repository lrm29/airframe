function [candidateInteraction, notImported] = buildCandidateInteraction(element)
    notImported = [];
    candidateInteraction = xmi.CandidateInteraction.Interaction(element.name, xmi.utils.getExtID(element), []);

    for lifelineIdx = 1:element.lifeline.size
        umlLifeline = element.lifeline.at(lifelineIdx);

        umlLifelineNameIdx = 1;
        umlLifelineNameParts = {};

        if ~isempty(umlLifeline.name)
            umlLifelineNameParts{umlLifelineNameIdx} = umlLifeline.name;
            umlLifelineNameIdx = umlLifelineNameIdx + 1;
        end
        
        % Reference ID should be the represents.type but if it was not
        % defined in the SysML model, then settle for whatever is
        % available.
        referenceID = [];
        if ~isempty(umlLifeline.represents)
            referenceID = xmi.utils.getExtID(umlLifeline.represents);

            if ~isempty(umlLifeline.represents.name)
                umlLifelineNameParts{umlLifelineNameIdx} = umlLifeline.represents.name;
                umlLifelineNameIdx = umlLifelineNameIdx + 1;
            end

            if ~isempty(umlLifeline.represents.type)
                referenceID = xmi.utils.getExtID(umlLifeline.represents.type);

                if ~isempty(umlLifeline.represents.type.name)
                    umlLifelineNameParts{umlLifelineNameIdx} = umlLifeline.represents.type.name;
                    umlLifelineNameIdx = umlLifelineNameIdx + 1;
                end
            end
        end

        umlLifelineName = strtrim(strjoin(umlLifelineNameParts, ' '));

        lifelineID = xmi.utils.getExtID(umlLifeline);
        lifeline = addLifeline(candidateInteraction, umlLifelineName, lifelineID);
        lifeline.ReferenceElementID = referenceID;

        if ~isempty(referenceID)
            % Capture the link between the lifeline and the referenced
            % element as an allocation.
            allocationID = sprintf('%s_%s', lifelineID, referenceID);
            xmi.CandidateAllocation.Allocation(lifelineID, referenceID, Name='', ExternalID=allocationID);
        end
    end
end