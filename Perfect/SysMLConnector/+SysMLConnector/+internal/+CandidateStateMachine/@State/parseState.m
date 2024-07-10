function parseState(this,element)
%PARSESTATE parses UML state
arguments
    this SysMLConnector.internal.CandidateStateMachine.State
    element umlmm.State
end
this.Name = element.name;
end

