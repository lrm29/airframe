classdef State < SysMLConnector.internal.CandidateStateMachine.Node
    %STATE represents a Stateflow state

    properties (SetAccess=protected)
        Name
    end

    properties (SetAccess=protected,Dependent)
        Width
        Height
        Center
    end

    methods
        function stateObj = State(element,parent)
            %STATE Construct an instance of this class
            arguments
                element {SysMLConnector.internal.CandidateStateMachine.State.validUMLSourceElement}
                parent SysMLConnector.internal.CandidateStateMachine.Region
            end
            stateObj@SysMLConnector.internal.CandidateStateMachine.Node(...
                SysMLConnector.internal.utils.getExtID(element),parent);
            switch class(element)
                case "umlmm.State"
                    stateObj.parseState(element);
                case "umlmm.FinalState"
                    stateObj.parseFinalState(element);
                otherwise
                    error("SysMLConnector:internal:CandidateStateMachine:State",...
                        "Unsupported element of type %s made it passed validation",...
                        class(element));
            end
        end

        function value = get.Width(this)
            arguments
                this SysMLConnector.internal.CandidateStateMachine.State
            end
            if ~isempty(this.StateflowObj)
                value = this.StateflowObj.Position(3);
            else
                value = 0;
            end
        end

        function value = get.Height(this)
            arguments
                this SysMLConnector.internal.CandidateStateMachine.State
            end
            if ~isempty(this.StateflowObj)
                value = this.StateflowObj.Position(4);
            else
                value = 0;
            end
        end

        function value = get.Center(this)
            arguments
                this SysMLConnector.internal.CandidateStateMachine.State
            end
            if ~isempty(this.StateflowObj)
                value = [this.StateflowObj.Position(1)+(this.Width/2),...
                    this.StateflowObj.Position(2)+(this.Height/2)];
            else
                value = [0,0];
            end
        end

        build(this);
    end

    methods (Access=protected)
        parseState(this,element);
        parseFinalState(this,element);
    end

    methods (Static)
        validUMLSourceElement(element);
    end
end

