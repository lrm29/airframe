classdef CandidateExplorer < handle
    %CANDIDATEEXPLORER explores candidate elements to make a mapping based on
    %external IDs
    
    properties (SetAccess=protected)
        dictionary dictionary = dictionary()
        propertyValidator function_handle
    end
    
    methods
        function obj = CandidateExplorer(propertyValidator)
            %CANDIDATEEXPLORER Construct an instance of this class
            % exclude field by exact name
            arguments
                propertyValidator function_handle = @(~) true
            end
            obj.propertyValidator = propertyValidator;
        end
        
        explore(obj,candidate);
    end
end

