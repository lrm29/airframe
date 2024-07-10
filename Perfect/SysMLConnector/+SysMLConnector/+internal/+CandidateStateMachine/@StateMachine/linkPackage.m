function linkPackage(this)
%LINKPACKAGE links to the parent package
arguments
    this SysMLConnector.internal.CandidateStateMachine.StateMachine
end
parentPackage = SysMLConnector.internal.CandidateElement.idMap(...
    "lookup",this.ParentPackageExtElementID);
parentPackage.addStateMachine(this);
this.ParentPackage = parentPackage;
end

