function infoString = getInfoString(this)
    %GETINFOSTRING generates information string for this fragment
    arguments
        this SysMLConnector.internal.CandidateInteraction.Fragment
    end
    if ~isempty(this.Type)
        infoString = string(this.Type);
    else
        infoString = string.empty();
    end
end