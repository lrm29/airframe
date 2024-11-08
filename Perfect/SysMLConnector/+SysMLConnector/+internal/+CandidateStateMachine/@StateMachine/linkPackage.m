function linkPackage(this)
%LINKPACKAGE links to the parent package
arguments
    this SysMLConnector.internal.CandidateStateMachine.StateMachine
end
resolveOwningPackage(this);
this.OwningPackage.addStateMachine(this);
end

