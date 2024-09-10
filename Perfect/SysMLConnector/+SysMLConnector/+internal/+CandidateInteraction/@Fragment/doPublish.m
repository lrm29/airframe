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
else
    if isempty(this.Type)
        % this is a message fragment
        % publish the message if not already build
        if ~this.Message.Built
            this.Message.publish();
        end
        %% link the fragment to the message event
        if this.Message.StartFragment == this
            this.ZCElement = this.Message.ZCElement.Start;
        elseif this.Message.EndFragment == this
            this.ZCElement = this.Message.ZCElement.End;
        else
            warning("SysMLConnector:internal:CandidateInteraction:Fragment",...
                    "Fragment %s could not be linked to either end of message %s.",...
                    this.ExtElementID,this.Message.ExtElementID);
        end
    elseif isempty(this.Message)
        % this is an interesting fragment
        % need to build the right fragment first
        operand = this.getOperand();
        this.ZCElement = operand.addFragment(string(this.Type),NumOperands=0);
        % publish the operands owned by this fragment
        arrayfun(@publish,this.Operands);
    else
        error("SysMLConnector:internal:CandidateInteraction:Fragment",...
            "Fragment with externalID %s has messages and contains other operands!",...
            this.ExtElementID);
    end
end
end