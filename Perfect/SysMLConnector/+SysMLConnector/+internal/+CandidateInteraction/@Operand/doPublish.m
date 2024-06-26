function doPublish(this, varargin)
%DOPUBLISH publishes the operand
arguments
    this SysMLConnector.internal.CandidateInteraction.Operand
end
arguments (Repeating)
    varargin
end
if isMATLABReleaseOlderThan("R2024b")
    % the API needed does not exist
    return;
else
    % add the operand
    this.ZCElement = this.Parent.ZCElement.addOperand(this.Guard);
    % publish the owned fragments
    arrayfun(@publish,this.Fragments);
end
end