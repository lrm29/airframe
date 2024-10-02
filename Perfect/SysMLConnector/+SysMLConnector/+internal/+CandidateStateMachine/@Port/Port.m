classdef Port < SysMLConnector.internal.CandidateStateMachine.Junction
    %PORT represent connection points as ports

    properties (SetAccess=protected)
        Junction SysMLConnector.internal.CandidateStateMachine.PortJunction ...
           = SysMLConnector.internal.CandidateStateMachine.PortJunction.empty
    end
    
    methods
        function portObj = Port(element,parent,portNumber)
            %PORT Construct an instance of this class
            arguments
                element umlmm.Pseudostate
                parent SysMLConnector.internal.CandidateStateMachine.State
                portNumber {mustBeNumeric}
            end
            portObj@SysMLConnector.internal.CandidateStateMachine.Junction(...
                element,parent);
            % determine port type
            portObj.Junction = ...
                SysMLConnector.internal.CandidateStateMachine.PortJunction(...
                element,portObj,portNumber);
            %% TODO: find better option
            % for now disable arrange by setting arrange count
            portObj.ArrangeCount = 1;
        end

        build(this);
        arrange(this);
        moveCenterTo(this,newCenter)
    end
end

