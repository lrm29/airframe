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
        
        if ~isempty(umlLifeline.represents)
            if ~isempty(umlLifeline.represents.name)
                umlLifelineNameParts{umlLifelineNameIdx} = umlLifeline.represents.name;
                umlLifelineNameIdx = umlLifelineNameIdx + 1;
            end

            if ~isempty(umlLifeline.represents.type) && ~isempty(umlLifeline.represents.type.name)
                umlLifelineNameParts{umlLifelineNameIdx} = umlLifeline.represents.type.name;
                umlLifelineNameIdx = umlLifelineNameIdx + 1;
            end
        end

        umlLifelineName = strtrim(strjoin(umlLifelineNameParts, ' '));

        addLifeline(candidateInteraction, umlLifelineName, xmi.utils.getExtID(umlLifeline));
    end
end