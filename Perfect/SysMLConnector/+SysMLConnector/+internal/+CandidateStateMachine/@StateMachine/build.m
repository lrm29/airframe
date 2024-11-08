function build(this)
    %BUILD populates state chart with data from the candidate state machine

    % Set the new model from the builder as the build root for the state
    % machine
    this.BuiltElement = find(sfroot,"-isa","Stateflow.Chart", ...
        Path=string(this.BuildName)+"/Chart");

    this.BuiltElement.Document = this.ExtElementID;

    arrayfun(@(r) r.build(),this.Regions);

    if ~isempty(this.Regions)
        Simulink.BlockDiagram.arrangeSystem(this.Regions.BuiltElement.Path, ...
            FullLayout='true');
    end
end

