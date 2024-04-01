classdef CandidateConnector < XMIChecker.Validator.Default
    %CANDIDATECONNECTOR validates connectors

    methods
        function obj = CandidateConnector(candidate,xmidb,foundElements)
            %CANDIDATECONNECTOR Construct an instance of this class
            arguments
                candidate SysMLImport.internal.CandidateConnector
                xmidb SysMLImport.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call the super constructor
            obj@XMIChecker.Validator.Default(candidate,xmidb,foundElements);
            % override result if Valid is false
            if ~candidate.Valid
                obj.fail = 0;
                obj.warn = 1+obj.warn;
            end
        end
    end
end

