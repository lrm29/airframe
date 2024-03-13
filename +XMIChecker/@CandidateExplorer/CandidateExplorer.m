classdef CandidateExplorer < handle
    %CANDIDATEEXPLORER explores candidate elements to make a mapping based on
    %external IDs
    
    properties (SetAccess=protected)
        dictionary dictionary = dictionary()
    end
    
    methods
        function obj = CandidateExplorer()
            %CANDIDATEEXPLORER Construct an instance of this class
        end
        
        explore(obj,candidate);
    end
end

