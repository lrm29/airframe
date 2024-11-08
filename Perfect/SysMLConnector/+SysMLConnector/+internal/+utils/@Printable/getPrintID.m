function idString = getPrintID(this)
    %GETPRINTID generates an identifier for the printable item
    arguments
        this SysMLConnector.internal.utils.Printable
    end
    
    type = string(class(this));
    type = strsplit(type,".");
    idString = type(end);
    if ~isempty(this.Name)
        idString = idString+": "+string(this.Name);
    end
end

