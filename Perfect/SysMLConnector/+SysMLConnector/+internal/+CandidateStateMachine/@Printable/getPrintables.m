function printables = getPrintables(item)
% checks what item is and tries to extract printable elements
printables = [];
if isa(item,"SysMLConnector.internal.CandidateStateMachine.Printable")
    printables = item;
elseif iscell(item)
    % if it is a cell
    printables = cellfun(...
        @(i) SysMLConnector.internal.CandidateStateMachine.Printable.getPrintables(i), ...
        item,UniformOutput=false);
    % output expected to be a cell so call self
    printables = ...
        SysMLConnector.internal.CandidateStateMachine.Printable.getPrintables( ...
        [printables{:}]);
elseif isa(item,"dictionary")
    % need to extract the values
    if item.isConfigured
        printables = ...
            SysMLConnector.internal.CandidateStateMachine.Printable.getPrintables( ...
            item.values);
    end
end
end