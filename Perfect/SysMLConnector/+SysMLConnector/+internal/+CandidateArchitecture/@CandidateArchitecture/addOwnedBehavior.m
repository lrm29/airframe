function addOwnedBehavior(this,behavior)
%ADDOWNEDBEHAVIOR adds an owned behavior
arguments
    this SysMLConnector.internal.CandidateArchitecture.CandidateArchitecture
    behavior SysMLConnector.internal.OwnedBehavior
end
this.OwnedBehaviors = [this.OwnedBehaviors,behavior];
end