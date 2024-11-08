classdef CandidateConnector < XMIChecker.Validator.Default
    %CANDIDATECONNECTOR validates connectors

    methods
        function obj = CandidateConnector(candidate,xmidb,foundElements)
            %CANDIDATECONNECTOR Construct an instance of this class
            arguments
                candidate SysMLConnector.internal.CandidateArchitecture.CandidateConnector
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call the super constructor
            obj@XMIChecker.Validator.Default(candidate,xmidb,foundElements);
            % override result if Valid is false
            obj.processBuildableFlag(candidate.Valid);
        end
    end
end

