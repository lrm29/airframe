function printables = getPrintables(item)
% checks what item is and tries to extract printable elements
printables = [];
if isa(item,"SysMLConnector.internal.utils.Printable")
    printables = item;
elseif iscell(item)
    % if it is a cell
    printables = cellfun(...
        @(i) SysMLConnector.internal.utils.Printable.getPrintables(i), ...
        item,UniformOutput=false);
    % output expected to be a cell so call self
    printables = ...
        SysMLConnector.internal.utils.Printable.getPrintables( ...
        [printables{:}]);
elseif isa(item,"dictionary")
    % need to extract the values
    if item.isConfigured
        printables = ...
            SysMLConnector.internal.utils.Printable.getPrintables( ...
            item.values);
    end
end
end