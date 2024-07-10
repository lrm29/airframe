function validUMLSourceElement(element)
%VALIDUMLSOURCEELEMENT validates elements used to construct a state
if ~(isa(element,"umlmm.State") || isa(element,"umlmm.FinalState"))
    error("SysMLConnector:internal:CandidateStateMachine:State",...
        "Element of type %s is not valid for creating a State",...
        class(element));
end
end