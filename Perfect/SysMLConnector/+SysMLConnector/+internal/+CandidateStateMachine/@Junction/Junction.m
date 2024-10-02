classdef Junction < SysMLConnector.internal.CandidateStateMachine.Node
    %JUNCTION represents a Stateflow junction

    properties (SetAccess=protected)
        Type
    end

    properties (SetAccess=protected,Dependent)
        Width
        Height
        Center
    end

    methods
        function junctionObj = Junction(element,parent)
            %JUNCTION Construct an instance of this class
            arguments
                element umlmm.Pseudostate
                parent SysMLConnector.internal.CandidateStateMachine.Stateflow
            end
            junctionObj@SysMLConnector.internal.CandidateStateMachine.Node(...
                element,parent);
            junctionObj.Type = element.kind;
        end

        function value = get.Width(this)
            arguments
                this SysMLConnector.internal.CandidateStateMachine.Junction
            end
            if ~isempty(this.StateflowObj)
                value = this.StateflowObj.Position.Radius;
            else
                value = 0;
            end
        end

        function value = get.Height(this)
            arguments
                this SysMLConnector.internal.CandidateStateMachine.Junction
            end
            value = this.Width;
        end

        function value = get.Center(this)
            arguments
                this SysMLConnector.internal.CandidateStateMachine.Junction
            end
            if ~isempty(this.StateflowObj)
                value = this.StateflowObj.Position.Center;
            else
                value = 0;
            end
        end

        build(this);
    end
end

