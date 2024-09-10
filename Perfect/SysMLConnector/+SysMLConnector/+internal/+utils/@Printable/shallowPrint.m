function shallowPrint(this,printer)
%SHALLOWPRINT minimal print to keep the print out readable
arguments
    this SysMLConnector.internal.utils.Printable
    printer SysMLConnector.internal.Printer
end
if isscalar(this)
    if this.Built
        printer.print(this.getPrintID());
    end
else
    arrayfun(@(p) p.shallowPrint(printer),this);
end
end