classdef AllocationSet < XMIChecker.Validator.Validator
    %ALLOCATIONSET validator for allocation sets
    
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
                    % also set warn as this should not happen
                    obj.warn = 1;
                    warning(ME.message);
                end
            else
                % wasn't built you say
                % check if if that is a lie
                if exist(string(candidate.BuildName)+".mldatx","file")
                    % you lied
                    obj.fail = 1;
                else
                    obj.pass = 1;
                end
            end
        end
    end
end

