classdef CandidateParameter < SysMLConnector.internal.CandidateArchitecture.Element
% CANDIDATEPARAMETER Helper class for SysMLConnector.internal.import that
% holds candidate Architecture and Component parameters
    properties
        Type
        TypeName
        Dim
        DefaultValue
    end

    properties
        Redefines = [];
    end

    methods
        function paramObj = CandidateParameter(varargin)
            paramObj@SysMLConnector.internal.CandidateArchitecture.Element(varargin{:});
        end

        function clonedParameter = cloneParameter(this, targetArch)
            clonedParameter = addParameter(targetArch, this.ExtElementID, ...
                                            this.Name, ...
                                            this.Type, ...
                                            this.TypeName, ...
                                            this.Dim, ...
                                            this.DefaultValue);
            clonedParameter.Owner = targetArch;
            
            if ~isempty(this.Redefines)
                targetArch.redefine(clonedParameter, this.Redefines);
            end
        end
    end
end