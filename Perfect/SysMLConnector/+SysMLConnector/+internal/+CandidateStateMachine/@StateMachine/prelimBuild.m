function prelimBuild(this,builder)
%PRELIMBUILD first step in build
arguments
    this SysMLConnector.internal.CandidateStateMachine.StateMachine
    builder SysMLConnector.internal.Builder
end
builder.createStateMachine(this);
end

