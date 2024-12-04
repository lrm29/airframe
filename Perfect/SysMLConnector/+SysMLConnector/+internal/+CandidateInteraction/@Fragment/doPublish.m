function doPublish(this, varargin)
%DOPUBLISH publishes the fragment
arguments
    this SysMLConnector.internal.CandidateInteraction.Fragment
end
arguments (Repeating)
    varargin
end
if this.Build
    if isMATLABReleaseOlderThan("R2024b")
        % before R2024b the API needed does not exist
        return;
    else
        if isempty(this.Type)
            % this is a message fragment
            % publish the message if not already build
            if ~this.Message.Built && ~this.Message.Invalid
                this.Message.publish();
            end
            %% link the fragment to the message event
            if this.Message.Built
                if this.Message.StartFragment == this
                    this.BuiltElement = this.Message.BuiltElement.Start;
                elseif this.Message.EndFragment == this
                    this.BuiltElement = this.Message.BuiltElement.End;
                else
                    warning("SysMLConnector:internal:CandidateInteraction:Fragment",...
                        "Fragment %s could not be linked to either end of message %s.",...
                        this.ExtElementID,this.Message.ExtElementID);
                end
            end
        elseif isempty(this.Message)
            % this is an interesting fragment
            % need to build the right fragment first
            operand = this.getOperand();
            this.BuiltElement = operand.addFragment(string(this.Type),NumOperands=0);
            % publish the operands owned by this fragment
            arrayfun(@publish,this.Operands);
        else
            error("SysMLConnector:internal:CandidateInteraction:Fragment",...
                "Fragment with externalID %s has messages and contains other operands!",...
                this.ExtElementID);
        end
    end
end
end