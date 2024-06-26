function operand = getOperand(this)
%GETOPERAND returns this operand
arguments
    this SysMLConnector.internal.CandidateInteraction.Operand
end
operand = this.ZCElement;
end

