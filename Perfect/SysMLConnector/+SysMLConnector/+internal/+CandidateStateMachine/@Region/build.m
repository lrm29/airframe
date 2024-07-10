function build(this)
%BUILD builds the region
arguments
    this SysMLConnector.internal.CandidateStateMachine.Region
end
% build the subvertexes
if this.Subvertexes.isConfigured
    arrayfun(@(n) n.build(),this.Subvertexes.values);
end
% then build the transitions that connect them
arrayfun(@(t) t.build(),this.Transitions);
% then try to make it look better
subvertexes = this.Subvertexes.values;
startingSubvertex = subvertexes(subvertexes.IsStart);
if isempty(startingSubvertex)
    startingSubvertex = subvertexes(1);
end
startingSubvertex.arrange();
end