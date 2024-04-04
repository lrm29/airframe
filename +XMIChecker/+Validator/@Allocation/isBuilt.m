function built = isBuilt(obj)
%SCENARIOBUILT deteremines if the allocation was built
% does not check if any required files exist so be careful
arguments
    obj XMIChecker.Validator.Allocation
end
% set default return of false
built = false;
% load the allocation set and start digging
allocationSet = systemcomposer.allocation.load(...
    obj.candidate.Parent.Parent.BuildName);
cleanUp = onCleanup(@() allocationSet.close(true));
scenario = allocationSet.Scenarios(...
    ismember({allocationSet.Scenarios.Name},obj.candidate.Parent.Name));
if isempty(scenario)
    return;
else
    % found the scenario
    % if multiple scenarios have the same name... give up
    assert(isscalar(scenario));
    % need to find the allocation in the scenario that matches the
    % allocation being looked for
    for i = 1:numel(scenario.Allocations)
        [sourceID,targetID] = getIDs(scenario.Allocations(i));
        if any(startsWith(sourceID,obj.candidate.SourceID)) && ...
                any(startsWith(targetID,obj.candidate.TargetID))
            % found the allocation!
            built = true;
            return;
        end
    end
end
end

function [source,target] = getIDs(allocation)
% gets IDs for an allocation
arguments
    allocation systemcomposer.allocation.Allocation
end
source = getID(allocation.Source);
target = getID(allocation.Target);
end

function id = getID(endPoint)
% gets ID from componet or architecture
arguments
    endPoint
end
if isa(endPoint,"systemcomposer.arch.Architecture")
    id = endPoint.ExternalUID;
    if isa(endPoint.Parent,"systemcomposer.arch.Component")
        id = {id,endPoint.Parent.ExternalUID};
    end
else
    id = {endPoint.ExternalUID,endPoint.Architecture.ExternalUID};
end
end