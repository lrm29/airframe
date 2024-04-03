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
            % validate an allocation set scenario
            if candidate.Build
                if obj.scenarioBuilt
                    % I was built
                    obj.pass = 1;
                else
                    % that's not good.. I am missing
                    obj.fail = 1;
                end
            else
                % wasn't built
                % check if parent was built
                if candidate.Parent.Build
                    % this does make sense....
                    % going to warn
                    obj.warn = 1;
                else
                    % neither was built?
                    % validate the parent and see from there
                    parentValidator = XMIChecker.Validator.build(...
                        candidate.Parent,xmidb,foundElements);
                    if parentValidator.pass > 0
                        % parent really wasn't built, good
                        obj.pass = 1;
                    elseif parentValidator.fail > 0
                        % LIES!!!
                        if obj.scenarioBuilt()
                            % I am not built but exist????
                            obj.fail = 1;
                        else
                            % I wasn't built, some lies but not directly me
                            % call this a warn
                            obj.warn = 1;
                        end
                    end
                end
            end
        end
    end

    methods (Access=protected)
        built = scenarioBuilt(obj);
    end
end

