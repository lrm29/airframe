classdef Node < SysMLConnector.internal.CandidateStateMachine.GraphicalElement & ...
        matlab.mixin.Heterogeneous
    %NODE an element of a state chart the transitions connect to
    % junctions or states

    properties (SetAccess=protected)
        StateflowObj
        IncomingTransitions
        OutgoingTransitions
        IsStart = false
        ArrangeCount = 0;
    end

    properties (SetAccess=protected,Dependent)
        ConnectionCount
        OClocksInUse
    end

    properties (SetAccess=protected,Abstract,Dependent)
        Width
        Height
        Center
    end

    properties (Constant)
        DefaultOffset = 120
    end

    methods
        function nodeObj = Node(externalElementID,parent)
            %NODE Construct an instance of this class
            arguments
                externalElementID {mustBeText}
                parent
            end
            nodeObj@SysMLConnector.internal.CandidateStateMachine.GraphicalElement(...
                externalElementID,parent);
            %% TODO: enable linking
        end

        function value = get.ConnectionCount(this)
            arguments
                this SysMLConnector.internal.CandidateStateMachine.Node
            end
            value = numel(this.IncomingTransitions) + ...
                numel(this.OutgoingTransitions);
        end

        function OClocksInUse = get.OClocksInUse(this)
            arguments
                this SysMLConnector.internal.CandidateStateMachine.Node
            end
            OClocksInUse = false(1,12);
            for i = 1:numel(this.IncomingTransitions)
                if this.IncomingTransitions(i).Arranged
                    OClocksInUse(this.toOClock( ...
                        this.IncomingTransitions(i).DestinationOClock)) = true;
                end
            end
            for i = 1:numel(this.OutgoingTransitions)
                if this.OutgoingTransitions(i).Arranged
                    OClocksInUse(this.toOClock( ...
                        this.OutgoingTransitions(i).SourceOClock)) = true;
                end
            end
        end

        addIncomingTransition(this,transition);
        addOutgoingTransition(this,transition);
        arrange(this);
        oClock = findNearestUnusedOClock(this,oClock);
        position = getOClockPosition(this,oClock);
        oClock = findClosestOClock(this,position); % finds the one closest to the position
    end

    methods (Abstract)
        moveCenterTo(this,newCenter);
    end
end

