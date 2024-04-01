classdef Scenario < XMIChecker.Validator.Validator
    %SCENARIO fake validator for Allocation Scenarios
    % allocations aren't real yet
    
    properties
        Property1
    end
    
    methods
        function obj = Scenario(candidate,~,~)
            %SCENARIO Construct an instance of this class
            arguments
                candidate (1,1) SysMLImport.internal.CandidateAllocation.Scenario
                ~ 
                ~ 
            end
            % store candidate
            obj.candidate = candidate;
            % do nothing else
        end
    end
end

