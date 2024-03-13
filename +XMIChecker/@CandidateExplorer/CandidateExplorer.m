classdef CandidateExplorer < handle
    %CANDIDATEEXPLORER explores candidate elements to make a mapping based on
    %external IDs
    
    properties (SetAccess=protected)
        dictionary dictionary = dictionary()
        exclusions string
    end
    
    methods
        function obj = CandidateExplorer(exclusions)
            %CANDIDATEEXPLORER Construct an instance of this class
            % exclude field by exact name
            arguments
                exclusions string = string.empty
            end
            obj.exclusions = exclusions;
        end
        
        explore(obj,candidate);
    end
end

