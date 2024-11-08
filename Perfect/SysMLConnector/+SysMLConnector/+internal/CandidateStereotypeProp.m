classdef CandidateStereotypeProp < SysMLConnector.internal.CandidateElement
% CANDIDATESTEREOTYPEPROP Helper class for SysMLConnector.internal.import that holds candidate Stereotype properties
    properties
        Datatype
        DatatypeName
        Enumtype
    end
    
    methods
        function this = CandidateStereotypeProp(extElemID, pName, pDtypeName, eType, owner)
            this@SysMLConnector.internal.CandidateElement(extElemID);

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
                          "<" + this.Datatype + "> [" + this.BuildName + "]");
        end
    end
end