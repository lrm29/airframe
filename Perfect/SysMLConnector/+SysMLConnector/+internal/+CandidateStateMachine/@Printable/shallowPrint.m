function shallowPrint(this,printer)
%SHALLOWPRINT minimal print to keep the print out readable
arguments
    this SysMLConnector.internal.CandidateStateMachine.Printable
    printer SysMLConnector.internal.Printer
end
if this.Built
    if isscalar(this)
        printer.print(this.getPrintID());
    else
        arrayfun(@(p) p.shallowPrint(printer),this);
    end
end
end