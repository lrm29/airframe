function shortPrint(this,printer)
%SHORTPRINT Short summary print that compresses the element into one line
arguments
    this SysMLConnector.internal.CandidateStateMachine.Printable
    printer SysMLConnector.internal.Printer
end
if isscalar(this)
    if this.Built
        shortString = this.getPrintID();
        printableProperties = this.getPrintableProperties();
        if ~isempty(printableProperties)
            shortString = shortString+": ";
            infoString = this.getInfoString();
            if ~isempty(infoString)
                shortString = shortString+infoString;
            end
            for i = 1:numel(printableProperties)
                printables = this.getPrintables(this.(printableProperties(i)));
                propertyString = arrayfun(@(p) p.getPrintID(),printables);
                if ~isscalar(propertyString)
                    propertyString = strjoin(propertyString,",");
                end
                shortString = shortString+"["+printableProperties(i)+"="+...
                    propertyString+"]";
            end
        else
            infoString = this.getInfoString();
            if ~isempty(infoString)
                shortString = shortString+": "+infoString;
            end
        end
        printer.print(shortString);
    end
else
    arrayfun(@(p) p.shortPrint(printer),this);
end
end

