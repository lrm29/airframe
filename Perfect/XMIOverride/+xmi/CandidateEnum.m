classdef CandidateEnum < xmi.CandidateElement
% CANDIDATEENUM Helper class for xmi.import that holds candidate enumerations.
    properties
        Name
        EnumStrs = []

        BuildName = ""
        BuildEnumStrs = []
        
    end
    
    methods
        function this = CandidateEnum(extElemID, eName, eStrs)
            this@xmi.CandidateElement(extElemID);

            this.Name = eName;
            this.EnumStrs = eStrs;
        end
    end
end
