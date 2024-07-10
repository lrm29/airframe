classdef Validator < handle
    %VALIDATOR base class for all validators
    % Picks correct validator for the type if no specific validator is
    % available switches to the default

    properties (SetAccess = protected)
        % results are stored, anything else will be delt with later
        pass {mustBeNumeric} = 0
        warn {mustBeNumeric} = 0
        fail {mustBeNumeric} = 0
        % store candidate data
        candidate
    end

    methods
        function validatorObj = Validator(candidate)
            arguments
                candidate = []
            end
            validatorObj.candidate = candidate;
        end
    end

    methods (Access = protected)
        processBuildableFlag(obj,flag);
    end

    methods (Access = public)
        report(obj);
    end
end

