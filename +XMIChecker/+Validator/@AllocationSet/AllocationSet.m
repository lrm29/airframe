classdef AllocationSet < XMIChecker.Validator.Validator
    %ALLOCATIONSET fake validator for allocation sets
    % allocations aren't real yet
    
    methods
        function obj = AllocationSet(candidate,~,~)
            %ALLOCATIONSET Construct an instance of this class
            arguments
                candidate (1,1) SysMLImport.internal.CandidateAllocation.AllocationSet
                ~ 
                ~ 
            end
            % store candidate
            obj.candidate = candidate;
            % do nothing else
        end
    end
end

