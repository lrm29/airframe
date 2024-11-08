classdef CandidateInterfaceElement < SysMLConnector.internal.CandidateElement
% CANDIDATEINTERFACEELEMENT Helper class for SysMLConnector.internal.import that holds candidate interface objects.
    properties
        Direction;
        TypeName;
        Type;
        Dim;
    end
    
    methods
        function this = CandidateInterfaceElement(interface, name, extID)
            this@SysMLConnector.internal.CandidateElement(extID);
            this.Name = name;
            this.Owner = interface;
            this.ValidRequirementLinkTarget = true;
        end

        function linkTarget = getLinkTarget(this)
            linkTarget = SysMLConnector.internal.utils.getInterfaceLinkTarget(this.Owner);            
        end
    end
end
