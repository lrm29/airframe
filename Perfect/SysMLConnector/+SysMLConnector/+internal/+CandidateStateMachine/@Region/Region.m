classdef Region < SysMLConnector.internal.CandidateStateMachine.Element
    %REGION represents a region from a SysML state machine

    properties (SetAccess=protected)
        Subvertexes dictionary = dictionary()
        Transitions SysMLConnector.internal.CandidateStateMachine.Transition ...
            = SysMLConnector.internal.CandidateStateMachine.Transition.empty
    end

    properties (Dependent,SetAccess=protected)
        StateflowObj
    end
    
    methods
        function regionObj = Region(element,parent,portJunctions)
            %REGION Construct an instance of this class
            arguments
                element umlmm.Region
                parent SysMLConnector.internal.CandidateStateMachine.RegionContainer
                portJunctions SysMLConnector.internal.CandidateStateMachine.PortJunction ...
                    = SysMLConnector.internal.CandidateStateMachine.PortJunction.empty
            end
            regionObj@SysMLConnector.internal.CandidateStateMachine.Element(...
                element,parent);
            %% parse the subvertexes
            for i = 1:element.subvertex.size
                umlSubvertex = element.subvertex.at(i);
                subvertex = [];
                switch class(umlSubvertex)
                    case "umlmm.Pseudostate"
                        % make a junction
                        subvertex = ...
                            SysMLConnector.internal.CandidateStateMachine.Junction(...
                            umlSubvertex,regionObj);
                    case {"umlmm.State","umlmm.FinalState"}
                        % make a state
                        subvertex = ...
                            SysMLConnector.internal.CandidateStateMachine.State(...
                            umlSubvertex,regionObj);
                    otherwise
                        warning("SysMLConnector:internal:CandidateStateMachine:Region",...
                            "State Machine node %s not handled and not reported as not imported",...
                            class(umlSubvertex));
                end
                if ~isempty(subvertex)
                    regionObj.Subvertexes(subvertex.ExtElementID) = subvertex;
                end
            end
            %% add port junctions if any
            if ~isempty(portJunctions)
                regionObj.Subvertexes([portJunctions.ExtElementID]) = portJunctions;
            end
            %% now parse the transitions
            regionObj.Transitions = ...
                SysMLConnector.internal.CandidateStateMachine.Transition.empty(element.transition.size,0);
            for i = 1:element.transition.size
                regionObj.Transitions(i) = ...
                    SysMLConnector.internal.CandidateStateMachine.Transition(...
                    element.transition.at(i),regionObj);
            end
        end

        function value = get.StateflowObj(this)
            arguments
                this SysMLConnector.internal.CandidateStateMachine.Region
            end
            value = this.Parent.StateflowObj;
        end

        build(this);
        addConnectionPoint(this,connectionPoint);
    end
end

