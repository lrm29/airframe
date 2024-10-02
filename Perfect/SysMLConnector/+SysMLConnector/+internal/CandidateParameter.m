classdef CandidateParameter < SysMLConnector.internal.CandidateElement
% CANDIDATEPARAMETER Helper class for SysMLConnector.internal.import that
% holds candidate Architecture and Component parameters
    properties
        Name
        Type
        TypeName
        Dim
        DefaultValue
    end

    properties
        Redefines = [];
        ParentArch
    end

    methods
        function clonedParameter = cloneParameter(this, targetArch)
            clonedParameter = addParameter(targetArch, this.ExtElementID, ...
                                            this.Name, ...
                                            this.Type, ...
                                            this.TypeName, ...
                                            this.Dim, ...
                                            this.DefaultValue);
            clonedParameter.ParentArch = targetArch;
            
            if ~isempty(this.Redefines)
                targetArch.redefine(clonedParameter, this.Redefines);
            end
        end
    end
end