function doPublish(this, varargin)
%DOPUBLISH publishes the fragment
arguments
    this SysMLConnector.internal.CandidateInteraction.Fragment
end
arguments (Repeating)
    varargin
end
if isMATLABReleaseOlderThan("R2024b")
    % before R2024b the API needed does not exist
    return;
elseif isempty(this.Type)
    % this is a message fragment
    arrayfun(@publish,this.Message);
elseif isempty(this.Message)
    % this is an interesting fragment
    % need to build the right fragment first
    operand = this.getOperand();
    this.ZCElement = operand.addFragment(string(this.Type),NumOperands=0);
    % mark that this was built
    this.Build = true;
    % publish the operands owned by this fragment
    arrayfun(@publish,this.Operands);
else
    error("Fragment with externalID %s has messages and contains other operands!",...
        this.ExtElementID);
end
end