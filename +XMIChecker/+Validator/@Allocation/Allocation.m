classdef Allocation < XMIChecker.Validator.Validator
    %ALLOCATION validator for allocations

    methods
        function obj = Allocation(candidate,xmidb,foundElements)
            %ALLOCATION Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateAllocation.Allocation
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % store candidate
            obj.candidate = candidate;
            % validate the allocation
            % check that the parent exists
            if isempty(candidate.Parent)
                if candidate.Build
                    % no parent but expected? no
                    obj.fail = 1;
                else
                    % this is weird
                    obj.warn = 1;
                end
                % no need to analyze nothing
                return;
            end
            % first check on the scenario that contains it
            scenarioValidator = XMIChecker.Validator.build(...
                candidate.Parent,xmidb,foundElements);
            % is the scenario built as expected or as not expected?
            if (scenarioValidator.pass > 0 && candidate.Parent.Build) || ...
                    (scenarioValidator.fail > 0 && ~candidate.Parent.Build)
                % scenario exists, check if the allocation does
                if xor(obj.isBuilt(),candidate.Build)
                    % that's not good...
                    obj.fail = 1;
                else
                    % the expected result was observed
                    obj.pass = 1;
                end
            else
                % scnenario wasn't built so cannot confirm if the
                % allocation was
                obj.warn = 1;
            end
        end
    end

    methods (Access=protected)
        built = isBuilt(obj);
    end
end