function build(this)
%BUILD builds the sate
arguments
    this SysMLConnector.internal.CandidateStateMachine.State
end
this.StateflowObj = Stateflow.State(this.Parent.StateflowObj);
if strcmp(this.LabelString,"")
    this.StateflowObj.Name = this.Name;
else
    this.StateflowObj.LabelString = string(this.Name)+newline+this.LabelString;
end
this.storeID();
%% shift right to avoid junctions
this.moveCenterTo(this.Center+[this.DefaultOffset,0]);
%% check for conflicts
this.deconflict();
%% build internals
if ~isempty(this.ConnectionPoints) || ~isempty(this.Regions)
    this.StateflowObj.IsSubchart = true;
end
arrayfun(@(r) r.build(),this.Regions);
arrayfun(@(cp) cp.build(),this.ConnectionPoints);
end

