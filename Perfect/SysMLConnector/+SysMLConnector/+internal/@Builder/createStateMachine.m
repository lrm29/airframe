function stateMachineMdl = createStateMachine(this,candStateMachine)
    %CREATESTATEMACHINE creates the state machine
    arguments
        this SysMLConnector.internal.Builder
        candStateMachine SysMLConnector.internal.CandidateStateMachine.StateMachine
    end

    if ~candStateMachine.Built
        % if the state machine is already built do not create it again
        buildName = this.getModelName(candStateMachine.Name);

        candStateMachine.BuildName = buildName;

        sfnew(buildName);

        candProj = candStateMachine.OwningPackage;

        mdlPath = this.ProjectPath + candProj.BuiltElement + filesep + ...
            buildName + ".slx";

        save_system(buildName, mdlPath);

        this.AllModelPaths = [this.AllModelPaths mdlPath];

        this.RootProject.addFile(mdlPath);

        stateMachineMdl = load_system(buildName);
        this.ArchModelExtIDMap(candStateMachine.ExtElementID) = stateMachineMdl;
    end

    this.Stats.NumStateMachines = this.Stats.NumStateMachines + 1;

    candStateMachine.build;
end