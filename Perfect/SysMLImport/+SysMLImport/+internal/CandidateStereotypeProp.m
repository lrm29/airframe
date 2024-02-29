classdef CandidateStereotypeProp < SysMLImport.internal.CandidateElement
% CANDIDATESTEREOTYPEPROP Helper class for SysMLImport.internal.import that holds candidate Stereotype properties
    properties
        Name
        Datatype
        DatatypeName
        Enumtype
        FinalName = ""
        
        Owner = []
        
        ZCElement = [];
    end
    
    methods
        function this = CandidateStereotypeProp(extElemID, pName, pDtypeName, eType, owner)
            this@SysMLImport.internal.CandidateElement(extElemID);

            this.Name = pName;
            this.DatatypeName = pDtypeName;
            this.Enumtype = eType;
            this.Owner = owner;
        end
        
        function trackAppliedElement(this, elem)
            this.AppliedElements = [this.AppliedElements elem];
        end
        
        function print(this, printer)
            printer.print("Prop: " + this.Name + ...
                          "<" + this.Datatype + "> [" + this.FinalName + "]");
        end
    end
end