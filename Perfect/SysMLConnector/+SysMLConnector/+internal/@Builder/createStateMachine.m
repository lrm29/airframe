function stateMachineMdl = createStateMachine(this,candStateMachine)
%CREATESTATEMACHINE creates the state machine
arguments
    this SysMLConnector.internal.Builder
    candStateMachine SysMLConnector.internal.CandidateStateMachine.StateMachine
end
SysMLConnector.internal.StatusMonitor.publishEvent('BuildStateMachine', ...
                candStateMachine.ExtElementID, ...
                'Building state machine %s (%i of %i).', ...
                candStateMachine.Name, this.getStateMachineIdx, this.StateMachineCount);
stateMachineName = this.getModelName(candStateMachine.Name);
stateMachineMdl = candStateMachine.build(stateMachineName);
candProj = candStateMachine.ParentPackage;
mdlPath = this.ProjectPath + candProj.ZCProjectFolder + filesep + ...
    stateMachineName + ".slx";
save_system(stateMachineMdl,mdlPath);
this.RootProject.addFile(mdlPath);
this.ArchModelExtIDMap(candStateMachine.ExtElementID) = stateMachineMdl;
this.Stats.NumStateMachines = this.Stats.NumStateMachines + 1;
end