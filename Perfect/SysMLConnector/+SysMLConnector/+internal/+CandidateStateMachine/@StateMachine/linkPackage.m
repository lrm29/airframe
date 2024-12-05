function linkPackage(this)
%LINKPACKAGE links to the parent package
arguments
    this SysMLConnector.internal.CandidateStateMachine.StateMachine
end
resolveOwningPackage(this);
this.OwningPackage.addStateMachine(this);
%% register with architecture if owned
if ~isempty(this.OwningArchitectureExtID)
    owner = SysMLConnector.internal.CandidateElement.idMap("lookup",this.OwningArchitectureExtID);
    if ~isempty(owner)
        owner.addOwnedBehavior(this);
    end
end
end

