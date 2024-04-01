classdef CandidateArchitecture < XMIChecker.Validator.Default
    %CANDIDATEARCHITECTURE validates CandidateArchitectures
    
    methods
        function obj = CandidateArchitecture(candidate,xmidb,foundElements)
            %CANDIDATEARCHITECTURE Construct an instance of this class
            arguments
                candidate SysMLImport.internal.CandidateArchitecture
                xmidb SysMLImport.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call the super constructor
            obj@XMIChecker.Validator.Default(candidate,xmidb,foundElements);
            % override result if build is false
            if ~candidate.Build
                obj.fail = 0;
                obj.warn = 1+obj.warn;
            end
        end
        
    end
end

