function storeID(this)
%STOREID stores the ID in the Stateflow object
if ~isempty(this.StateflowObj)
    % only can store data if the object exists
    this.StateflowObj.Document = this.ExtElementID;
    % if the Stateflow object exists and the ID is stored it must have been
    % built
    this.Built = true;
end
end

