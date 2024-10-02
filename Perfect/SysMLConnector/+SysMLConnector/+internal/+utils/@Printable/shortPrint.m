function shortPrint(this,printer)
%SHORTPRINT Short summary print that compresses the element into one line
arguments
    this SysMLConnector.internal.utils.Printable
    printer SysMLConnector.internal.Printer
end
if isscalar(this)
    if this.Built
        printer.print(this.getShortPrintString());
    end
else
    arrayfun(@(p) p.shortPrint(printer),this);
end
end

