function built = scenarioBuilt(obj)
%SCENARIOBUILT deteremines if the scenario was built
% does not check if any required files exist so be careful
allocationSet = systemcomposer.allocation.load(...
    obj.candidate.Parent.BuildName);
built = ismember(obj.candidate.Name,{allocationSet.Scenarios.Name});
end

