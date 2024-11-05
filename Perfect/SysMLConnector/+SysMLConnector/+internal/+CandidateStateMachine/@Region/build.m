function build(this)
%BUILD builds the region
arguments
    this SysMLConnector.internal.CandidateStateMachine.Region
end
% build the subvertexes
if this.Subvertexes.isConfigured
    % build states first to avoid issues
    subvertexes = this.Subvertexes.values;
    areStates = arrayfun(@(s) ...
        isa(s,"SysMLConnector.internal.CandidateStateMachine.State"), ...
        subvertexes);
    states = subvertexes(areStates);
    notStates = subvertexes(~areStates);
    arrayfun(@(s) s.build(),states);
    arrayfun(@(n) n.build(),notStates);
end
% then build the transitions that connect them
arrayfun(@(t) t.build(),this.Transitions);
% then try to make it look better
subvertexes = this.Subvertexes.values;
startingSubvertex = subvertexes([subvertexes.IsStart]);
if isempty(startingSubvertex)
    startingSubvertex = subvertexes(1);
end
arrayfun(@(ss) ss.arrange(),startingSubvertex);
this.Built = true;
end