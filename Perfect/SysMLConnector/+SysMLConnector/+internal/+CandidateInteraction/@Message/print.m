function print(this,printer)
    %PRINT override print to always be short
    arguments
        this SysMLConnector.internal.CandidateInteraction.Message
        printer SysMLConnector.internal.Printer
    end
    this.shortPrint(printer);
end