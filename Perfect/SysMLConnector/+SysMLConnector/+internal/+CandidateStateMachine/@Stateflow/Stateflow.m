classdef Stateflow < SysMLConnector.internal.CandidateComment.Commentable
    %STATEFLOW base class for classes that link to Stateflow
    
    properties (Abstract,SetAccess=protected)
        StateflowObj
        Built
    end

    methods
        appendComment(this,comment)
    end
end

