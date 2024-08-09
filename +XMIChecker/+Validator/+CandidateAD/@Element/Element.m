classdef Element < XMIChecker.Validator.Default
    %ELEMENT validator for classes derived from Element
    
    methods
        function elementObj = Element(candidate,xmidb,foundElements)
            %ELEMENT Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateAD.Element
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call super constructor
            elementObj@XMIChecker.Validator.Default(candidate,xmidb,foundElements);
            % process flag 
            elementObj.processBuildableFlag(candidate.Built);
        end
       
    end
end

