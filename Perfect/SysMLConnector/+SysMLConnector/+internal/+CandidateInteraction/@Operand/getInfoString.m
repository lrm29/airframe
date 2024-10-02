function infoString = getInfoString(this)
    %GETINFOSTRING generates info string for the operand
    arguments
        this SysMLConnector.internal.CandidateInteraction.Operand
    end
    infoString = "["+this.Guard+"]";
end