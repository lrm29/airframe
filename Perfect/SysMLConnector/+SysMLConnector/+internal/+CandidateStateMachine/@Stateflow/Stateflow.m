classdef Stateflow < handle
    %STATEFLOW base class for classes that link to Stateflow
    
    properties (Abstract,SetAccess=protected)
        StateflowObj
    end
end

