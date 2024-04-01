classdef CandidateComponent < XMIChecker.Validator.Default
    %CANDIDATECOMPONENT validates candidate components
    
    methods
        function obj = CandidateComponent(candidate,xmidb,foundElements)
            %CANDIDATECOMPONENT Construct an instance of this class
            arguments
                candidate SysMLImport.internal.CandidateComponent
                xmidb SysMLImport.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call the super constructor
            obj@XMIChecker.Validator.Default(candidate,xmidb,foundElements);
            % override result if Valid is false
            obj.processBuildableFlag(candidate.Valid);
        end
    end
end

