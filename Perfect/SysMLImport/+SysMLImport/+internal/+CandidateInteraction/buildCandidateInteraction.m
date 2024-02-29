function [candidateInteraction, notImported] = buildCandidateInteraction(element)
    notImported = [];
    candidateInteraction = SysMLImport.internal.CandidateInteraction.Interaction(element.name, SysMLImport.internal.utils.getExtID(element), []);

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
            referenceID = SysMLImport.internal.utils.getExtID(umlLifeline.represents);

            if ~isempty(umlLifeline.represents.name)
                umlLifelineNameParts{umlLifelineNameIdx} = umlLifeline.represents.name;
                umlLifelineNameIdx = umlLifelineNameIdx + 1;
            end

            if ~isempty(umlLifeline.represents.type)
                referenceID = SysMLImport.internal.utils.getExtID(umlLifeline.represents.type);

                if ~isempty(umlLifeline.represents.type.name)
                    umlLifelineNameParts{umlLifelineNameIdx} = umlLifeline.represents.type.name;
                    umlLifelineNameIdx = umlLifelineNameIdx + 1;
                end
            end
        end

        umlLifelineName = strtrim(strjoin(umlLifelineNameParts, ' '));

        lifelineID = SysMLImport.internal.utils.getExtID(umlLifeline);
        lifeline = addLifeline(candidateInteraction, umlLifelineName, lifelineID);
        lifeline.ReferenceElementID = referenceID;

        if ~isempty(referenceID)
            % Capture the link between the lifeline and the referenced
            % element as an allocation.
            allocationID = sprintf('%s_%s', lifelineID, referenceID);
            SysMLImport.internal.CandidateAllocation.Allocation(lifelineID, referenceID, Name='', ExternalID=allocationID);
        end
    end
end