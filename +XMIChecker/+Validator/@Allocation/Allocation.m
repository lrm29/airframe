classdef Allocation < XMIChecker.Validator.Validator
    %ALLOCATION fake validator for allocations
    % allocations aren't real yet
    
    methods
        function obj = Allocation(candidate,~,~)
            %ALLOCATION Construct an instance of this class
            arguments
                candidate (1,1) SysMLImport.internal.CandidateAllocation.Allocation
                ~ 
                ~ 
            end
            % store candidate
            obj.candidate = candidate;
            % do nothing else
        end
        
    end
end

