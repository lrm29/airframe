function operand = getOperand(this)
%GETOPERAND returns the operand of this fragments parent
arguments
    this SysMLConnector.internal.CandidateInteraction.Fragment
end
operand = this.Owner.getOperand();
end

