function openCount = closeDataDictionaries()
%CLOSEDATADICTIONARIES closes all data dictionaries
openCount = 0;
if ~isempty(Simulink.data.dictionary.getOpenDictionaryPaths)
    openDDs = Simulink.data.dictionary.getOpenDictionaryPaths();
    cellfun( ...
        @(odd) warning("Data dictionary %s was left open and will be closed.",odd), ...
        openDDs);
    openCount = numel(openDDs);
    Simulink.data.dictionary.closeAll('-discard');
end
end

