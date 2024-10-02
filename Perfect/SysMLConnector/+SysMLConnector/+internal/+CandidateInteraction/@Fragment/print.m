function print(this,printer)
%PRINT short print for message fragments
arguments
    this SysMLConnector.internal.CandidateInteraction.Fragment
    printer SysMLConnector.internal.Printer
end
if this.Built
    if isempty(this.Type)
        % message fragment
        if isempty(this.Message)
            this.shortPrint(printer);
        else
            if this.Message.StartFragment == this
                printer.print( ...
                    "Message Fragment: "+this.Message.getShortPrintString);
            else
                % do not print duplicate message
            end
        end
    else
        % non-message fragment
        print@SysMLConnector.internal.utils.Printable(this,printer);
    end
end
end