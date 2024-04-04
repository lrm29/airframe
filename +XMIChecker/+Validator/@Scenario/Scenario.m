classdef Scenario < XMIChecker.Validator.Validator
    %SCENARIO validator for Allocation Scenarios    
    
    methods
        function obj = Scenario(candidate,xmidb,foundElements)
            %SCENARIO Construct an instance of this class
            arguments
                candidate (1,1) SysMLImport.internal.CandidateAllocation.Scenario
                xmidb SysMLImport.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % store candidate
            obj.candidate = candidate;
            return;
            % validate an allocation set scenario
            % validate the parent and see from there
            parentValidator = XMIChecker.Validator.build(...
                candidate.Parent,xmidb,foundElements);
            % if the parent exists then the scenario needs to be checked
            if (parentValidator.pass > 0 && candidate.Parent.Build) || ...
                    (parentValidator.fail > 0 && ~candidate.Parent.Build)
                % this means that the parent exists
                if xor(obj.isBuilt(),candidate.Build)
                    % built or not, its not what was promissed
                    obj.fail = 1;
                else
                    % the expected result was observed
                    obj.pass = 1;
                end
            else
                % parent does not exist
                % cannot confirm the scenario exists, going to report warn
                % to be safe
                obj.warn = 1;
            end
        end
    end

    methods (Access=protected)
        built = isBuilt(obj);
    end
end

