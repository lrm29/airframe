function build(this)
%BUILD builds the sate
arguments
    this SysMLConnector.internal.CandidateStateMachine.State
end
this.StateflowObj = Stateflow.State(this.Parent.StateflowObj);
this.StateflowObj.Name = this.Name;
this.storeID();
if ~isempty(this.ConnectionPoints) || ~isempty(this.Regions)
    this.StateflowObj.IsSubchart = true;
end
arrayfun(@(r) r.build(),this.Regions);
arrayfun(@(cp) cp.build(),this.ConnectionPoints);
end

