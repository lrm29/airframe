classdef CandidateEnum < SysMLImport.internal.CandidateElement
% CANDIDATEENUM Helper class for SysMLImport.internal.import that holds candidate enumerations.
    properties
        Name
        EnumStrs = []

        BuildName = ""
        BuildEnumStrs = []
        
    end
    
    methods
        function this = CandidateEnum(extElemID, eName, eStrs)
            this@SysMLImport.internal.CandidateElement(extElemID);

            this.Name = eName;
            this.EnumStrs = eStrs;
        end
    end
end
