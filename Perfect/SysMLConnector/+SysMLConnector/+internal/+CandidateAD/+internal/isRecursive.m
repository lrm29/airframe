function tf = isRecursive(this, nextComponent)
    % Return true if this 
    tf = false;

    if ~isa(this, 'SysMLConnector.internal.CandidateAD.Activity') || isempty(this.ReferenceID)
        return;
    end

    thisID = this.ReferenceID;

    if nargin < 2
        nextComponent = this.Owner;
    end
    
    while ~isempty(nextComponent)
        nextComponentID = nextComponent.ExternalID; 
           % Check if an activity references its own model
        if strcmp(thisID, nextComponentID) || ...
                ... % Check if an activity references its referenced model
                (isa(nextComponent, 'SysMLConnector.internal.CandidateAD.Activity') && ~isempty(nextComponent.ReferenceID) && strcmp(thisID, nextComponent.ReferenceID))
            tf = true;
            return
        end

        nextComponent = nextComponent.Owner;
    end
end