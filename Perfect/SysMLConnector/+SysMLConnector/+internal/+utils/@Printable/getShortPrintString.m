function shortString = getShortPrintString(this)
%GETSHORTPRINTSTRING generates short print string
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
end