classdef (Abstract) Validator
    %VALIDATOR base class for all validators
    % validates 
    
    properties (SetAccess = protected)
        % results are stored, anything else will be delt with later
        pass {mustBeNumeric} = 0
        warn {mustBeNumeric} = 0
        fail {mustBeNumeric} = 0
    end
end

