classdef Fragment < XMIChecker.Validator.Default
    %FRAGMENT validates fragments

    methods
        function obj = Fragment(candidate,xmidb,foundElements)
            %FRAGMENT Construct an instance of this class
            arguments
                candidate SysMLConnector.internal.CandidateInteraction.Fragment
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            obj@XMIChecker.Validator.Default(candidate,xmidb,foundElements);
            obj.processBuildableFlag(candidate.Build);
        end
    end
end

