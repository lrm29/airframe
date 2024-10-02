function printableProperties = getPrintableProperties(this)
%GETPRINTABLEPROPERTIES helper function to find which properties are
%printable
arguments
    this SysMLConnector.internal.utils.Printable
end
printableProperties = string(properties(this));
% remove excluded properties
printableProperties = printableProperties( ...
    ~ismember(printableProperties,this.ExcludedProperties));
printableProperties = printableProperties(...
    arrayfun(@(pp) isPrintable(this,pp),printableProperties));
end

function printable = isPrintable(this,propertyName)
% determines if property named is printable
arguments
    this SysMLConnector.internal.utils.Printable
    propertyName string
end
printable = false;
try
    printable = ~isempty(this.getPrintables(this.(propertyName)));
catch
    % do nothing it is not printable
end
end

