function operand = getOperand(this)
%GETOPERAND returns the root operand
arguments
    this SysMLConnector.internal.CandidateInteraction.Interaction
end
if isempty(this.ZCElement)
    operand = [];
else
    operand = this.ZCElement.Model.Interactions.RootFragment.Operands(1);
end
end

