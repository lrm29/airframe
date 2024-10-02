function build(this)
    %BUILD populates state chart with data from the candidate state machine

    % Set the new model from the builder as the build root for the state
    % machine
    this.StateflowObj = find(sfroot,"-isa","Stateflow.Chart", ...
        Path=string(this.BuildName)+"/Chart");

    this.StateflowObj.Document = this.ExtElementID;

    arrayfun(@(r) r.build(),this.Regions);

    if ~isempty(this.Regions)
        Simulink.BlockDiagram.arrangeSystem(this.Regions.StateflowObj.Path, ...
            FullLayout='true');
    end
end

