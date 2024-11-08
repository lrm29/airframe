function storeID(this)
%STOREID stores the ID in the Stateflow object
if ~isempty(this.BuiltElement)
    % only can store data if the object exists
    this.BuiltElement.Document = this.ExtElementID;
end
end

