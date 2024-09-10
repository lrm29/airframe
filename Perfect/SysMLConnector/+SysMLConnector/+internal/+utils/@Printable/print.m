function print(this,printer)
%PRINT prints state machine component
arguments
    this SysMLConnector.internal.utils.Printable
    printer SysMLConnector.internal.Printer
end
if isscalar(this)
    if this.Built
        printer.openScope(this.getPrintID());
        infoString = this.getInfoString();
        if ~isempty(infoString)
            printer.print(infoString);
        end
        printableProperties = this.getPrintableProperties();
        for i = 1:numel(printableProperties)
            printables = this.getPrintables(this.(printableProperties(i)));
            if ~isempty(printables)
                printer.openScope(printableProperties(i));
                if ismember(printableProperties(i),this.ShallowProperties)
                    arrayfun(@(p) p.shallowPrint(printer),printables);
                elseif ismember(printableProperties(i),this.ShortProperties)
                    arrayfun(@(p) p.shortPrint(printer),printables);
                else
                    arrayfun(@(p) p.print(printer),printables);
                end
                printer.closeScope(printableProperties(i));
            end
        end
        printer.closeScope(this.getPrintID());
    end
else
    % only do one at a time
    arrayfun(@(p) p.print(printer),this);
end
end