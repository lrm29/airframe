function built = isBuilt(obj)
%SCENARIOBUILT deteremines if the scenario was built
% does not check if any required files exist so be careful
allocationSet = systemcomposer.allocation.load(...
    obj.candidate.Parent.BuildName);
cleanUp = onCleanup(@() allocationSet.close(true));
built = ismember(obj.candidate.Name,{allocationSet.Scenarios.Name});
end

