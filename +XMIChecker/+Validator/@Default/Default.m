classdef Default < XMIChecker.Validator.Validator
    %DEFAULT default validator for all types

    methods
        function obj = Default(candidate,xmidb,foundElements)
            %DEFAULT Construct an instance of this class
            % processes elements on arrival
            obj@XMIChecker.Validator.Validator(candidate);
            if iscell(candidate)
                % assume this is a cell fun
                obj = cellfun(...
                    @(c) XMIChecker.Validator.Default(c,xmidb,foundElements), ...
                    candidate,UniformOutput=false);
            elseif isscalar(candidate)
                % have a single candidate
                % check which combination of places the ID is found
                if startsWith(candidate.ExtElementID,xmidb.LookupTable.keys)
                    if any(startsWith(foundElements.keys,candidate.ExtElementID))
                        % this means the ID was found in the XML and the
                        % imported files
                        obj.pass = 1;
                    else
                        % found in the XML but the element wasn't found
                        % this is a failure
                        obj.fail = 1;
                    end
                else
                    % going to be a warning 
                    % might put some diagnostic checks here later
                    obj.warn = 1;
                end
            else
                % assume this is an array
                obj = arrayfun(...
                    @(c) XMIChecker.Validator.Default(c,xmidb,foundElements), ...
                    candidate);
            end
        end
    end
end

