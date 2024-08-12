function modelHandle = build(this,name)
    %BUILD creates Stateflow object using sfnew
    arguments
        this SysMLConnector.internal.CandidateStateMachine.StateMachine
        name {mustBeText}
    end
    this.BuildName = name;

    sfnew(name);

    this.StateflowObj = find(sfroot,"-isa","Stateflow.Chart", ...
        Path=string(name)+"/Chart");

    modelHandle = load_system(name);

    arrayfun(@(r) r.build(),this.Regions);

    if ~isempty(this.Regions)
        Simulink.BlockDiagram.arrangeSystem(this.Regions.StateflowObj.Path, ...
            FullLayout='true');
    end
end

