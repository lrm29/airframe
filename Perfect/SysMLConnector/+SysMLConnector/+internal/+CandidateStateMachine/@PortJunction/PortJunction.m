classdef PortJunction < SysMLConnector.internal.CandidateStateMachine.Junction
    %PORTJUNCTION represents the junction end of a port

    properties (SetAccess=protected)
        PortType
        PortNumber
    end

    methods
        function portJunctionObj = PortJunction(element,parent,portNumber)
            %PORTJUNCTION Construct an instance of this class
            arguments
                element umlmm.Pseudostate
                parent SysMLConnector.internal.CandidateStateMachine.Port
                portNumber {mustBeNumeric}
            end
            portJunctionObj@SysMLConnector.internal.CandidateStateMachine.Junction(...
                element,parent);
            switch element.kind
                case umlmm.PseudostateKind.ExitPoint
                    portJunctionObj.PortType = 'ExitJunction';
                case umlmm.PseudostateKind.EntryPoint
                    portJunctionObj.PortType = 'EntryJunction';
                otherwise
                    error("SysMLConnector:internal:CandidateStateMachine:PortJunction",...
                        "Unsupported connection point type %s element with ID %s not imported.", ...
                        element.kind.toString,...
                        SysMLConnector.internal.utils.getExtID(element));
            end
            portJunctionObj.PortNumber = portNumber;
        end

        build(this);
    end
end

