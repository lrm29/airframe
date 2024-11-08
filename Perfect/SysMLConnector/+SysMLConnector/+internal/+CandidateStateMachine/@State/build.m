function build(this)
%BUILD builds the sate
arguments
    this SysMLConnector.internal.CandidateStateMachine.State
end
this.BuiltElement = Stateflow.State(this.Owner.BuiltElement);
if strcmp(this.LabelString,"")
    this.BuiltElement.Name = this.Name;
else
    this.BuiltElement.LabelString = string(this.Name)+newline+this.LabelString;
end
this.storeID();
if ~isempty(this.ConnectionPoints) || ~isempty(this.Regions)
    this.BuiltElement.IsSubchart = true;
end
arrayfun(@(r) r.build(),this.Regions);
arrayfun(@(cp) cp.build(),this.ConnectionPoints);
end

