classdef CandidateInterfaceElement < SysMLImport.internal.CandidateElement
% CANDIDATEINTERFACEELEMENT Helper class for SysMLImport.internal.import that holds candidate interface objects.
    properties
        Name = "";
        Interface = [];

        Direction;
        TypeName;
        Type;
        Dim;
    end
    
    methods
        function this = CandidateInterfaceElement(interface, name, extID)
            this@SysMLImport.internal.CandidateElement(extID);
            this.Name = name;
            this.Interface = interface;
            this.ValidRequirementLinkTarget = true;
        end

        function linkTarget = getLinkTarget(this)
            linkTarget = SysMLImport.internal.utils.getInterfaceLinkTarget(this.Interface);            
        end
    end
end
