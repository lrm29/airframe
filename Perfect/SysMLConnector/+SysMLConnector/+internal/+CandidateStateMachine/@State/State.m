classdef State < SysMLConnector.internal.CandidateStateMachine.Node & ...
        SysMLConnector.internal.CandidateStateMachine.RegionContainer
    %STATE represents a Stateflow state

    properties (SetAccess=protected)
        Name
        ConnectionPoints SysMLConnector.internal.CandidateStateMachine.Port ...
            = SysMLConnector.internal.CandidateStateMachine.Port.empty
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
                    %% parse connection points
                    stateObj.ConnectionPoints = ...
                        SysMLConnector.internal.CandidateStateMachine.Port.empty(element.connectionPoint.size,0);
                    for i = 1:element.connectionPoint.size
                        stateObj.ConnectionPoints(i) = ...
                            SysMLConnector.internal.CandidateStateMachine.Port(...
                            element.connectionPoint.at(i),stateObj,i);
                    end
                    % report the connection points to the parent
                    parent.addConnectionPoint(stateObj.ConnectionPoints);
                    %% parse regions
                    % expect this to be 1                    
                    stateObj.Regions = ...
                        SysMLConnector.internal.CandidateStateMachine.Region.empty(element.region.size,0);
                    for i = 1:element.region.size
                        stateObj.Regions(i) = ...
                            SysMLConnector.internal.CandidateStateMachine.Region(...
                            element.region.at(i),stateObj,...
                            [stateObj.ConnectionPoints.Junction]);
                    end
                    if element.region.size > 1
                        warning("SysMLConnector:internal:CandidateStateMachine:State",...
                            "State %s with ID %s contained %d regions, this is not expected please contact MathWorks.",...
                            stateObj.Name,stateObj.ExtElementID,element.region.size);
                    end
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

