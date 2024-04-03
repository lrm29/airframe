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
            % now to validate an allocation set
            % assumes that validation occurs in project that was imported
            if candidate.Build
                % assume it's built
                try
                    allocationSet = systemcomposer.allocation.load(...
                        candidate.BuildName);
                    if strcmp(allocationSet.SourceModel.Name, ...
                            candidate.BuildSource) && ...
                            strcmp(allocationSet.TargetModel.Name, ...
                            candidate.BuildTarget)
                        obj.pass = 1;
                    else
                        % set doesn't connect what it is supposed to
                        obj.fail = 1;
                    end
                catch ME
                    % if validation fails assume failure
                    obj.fail = 1;
                end
            else
                % wasn't built?
                % no result?
            end
        end
    end
end

