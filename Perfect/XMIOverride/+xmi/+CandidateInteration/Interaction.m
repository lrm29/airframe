classdef Interaction < CandidateInteraction.Element
    properties
        Model
    end

    methods
        function interObj = Interaction(name, externalID, parent)
            interObj@CandidateInteraction.Element(name, externalID, parent);
        end

        function setModel(this)
            % method override during construction.
            this.Model = this;
        end
    end
end