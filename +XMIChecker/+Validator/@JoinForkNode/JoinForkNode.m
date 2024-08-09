classdef JoinForkNode < XMIChecker.Validator.CandidateAD.Element
    %JOINFORKNODE Summary of this class goes here
    methods
        function joinForkObj = JoinForkNode(candidate,xmidb,foundElements)
            %JOINFORKNODE Construct an instance of this class
             arguments
                candidate (1,1) SysMLConnector.internal.CandidateAD.JoinForkNode
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call super constructor
            joinForkObj@XMIChecker.Validator.CandidateAD.Element(candidate,xmidb,foundElements);
        end
    end
end

