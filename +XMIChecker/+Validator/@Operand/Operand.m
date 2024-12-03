classdef Operand < XMIChecker.Validator.Default
    %OPERAND validates operands

    methods
        function obj = Operand(candidate,xmidb,foundElements)
            %OPERAND Construct an instance of this class
            arguments
                candidate (1,1) SysMLConnector.internal.CandidateInteraction.Operand
                xmidb SysMLConnector.internal.CandidateAD.internal.XMIDatabase
                foundElements dictionary
            end
            % call th super
            obj@XMIChecker.Validator.Default(candidate,xmidb,foundElements);
            % check flag
            obj.processBuildableFlag(candidate.Built);
        end
    end
end