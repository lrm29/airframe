function operand = getOperand(this)
%GETOPERAND returns the root operand
arguments
    this SysMLConnector.internal.CandidateInteraction.Interaction
end
if isempty(this.BuiltElement)
    operand = [];
else
    operand = this.BuiltElement.Model.Interactions.RootFragment.Operands(1);
end
end

