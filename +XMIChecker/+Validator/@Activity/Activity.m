classdef Activity < XMIChecker.Validator.CandidateAD.Element
    %ACTIVITY validates AD activities
    
    methods
        function activityObj = Activity(candidate,xmidb,foundElements)
            %ACTIVITY Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateAD.Activity
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call super constructor
            activityObj@XMIChecker.Validator.CandidateAD.Element(candidate,xmidb,foundElements);
        end
    end
end
