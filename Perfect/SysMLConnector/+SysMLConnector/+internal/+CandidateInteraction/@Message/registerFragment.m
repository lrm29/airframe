function registerFragment(this, fragment)
%REGISTERFRAGMENT registers a fragment as one end of the message so it can
%be linked to the right ZCElement later
arguments
    this SysMLConnector.internal.CandidateInteraction.Message
    fragment SysMLConnector.internal.CandidateInteraction.Fragment
end
if this.To == this.From 
    % this means this is a message to self and requires special logic
    % this logic assumes the start fragment is first in the XMI file
    if isempty(this.StartFragment)
        this.StartFragment = fragment;
    elseif isempty(this.EndFragment)
        this.EndFragment = fragment;
    else
        error("SysMLConnector:internal:CandidateInteraction:Message",...
            "Fragment with external ID %s tried to register with message with external ID %s but both end fragments have been registered.",...
            fragment.ExtElementID,this.ExtElementID);
    end
else
    if this.To == fragment.Lifeline
        this.StartFragment = fragment;
    elseif this.From == fragment.Lifeline
        this.EndFragment = fragment;
    else
        error("SysMLConnector:internal:CandidateInteraction:Message",...
            "Fragment with external ID %s tried to register with message with external ID %s but did not relate to messages lifelines.",...
            fragment.ExtElementID,this.ExtElementID);
    end
end

