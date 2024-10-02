classdef Comment < XMIChecker.Validator.Validator
    %COMMENT Validates Comments

    methods
        function commentValidatorObj = Comment(candidate,xmidb,foundElements)
            %COMMENT Construct an instance of this class
            arguments
                candidate SysMLConnector.internal.CandidateComment.Comment
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call super for basic setup
            commentValidatorObj@XMIChecker.Validator.Validator(candidate);

            % now to determine the result
            if candidate.Valid
                % comments are to hard to check directly so check the elements
                % it annotates
                annotatedValidators = cellfun(...
                    @(ae) XMIChecker.Validator.build(ae,xmidb,foundElements), ...
                    candidate.AnnotatedElement,UniformOutput=false);
                % take the results from the new validators directly
                commentValidatorObj.pass = sum( ...
                    cellfun(@(v) v.pass,annotatedValidators));
                commentValidatorObj.fail = sum( ...
                    cellfun(@(v) v.fail,annotatedValidators));
                commentValidatorObj.warn = sum( ...
                    cellfun(@(v) v.warn,annotatedValidators));
            else
                % if it is not valid just pass
                commentValidatorObj.pass = 1;
            end
        end
    end
end

