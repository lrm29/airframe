classdef GraphicalElement < SysMLConnector.internal.CandidateStateMachine.Element
    %GRAPHICALELEMENT represents graphical elements of the state machine

    properties (SetAccess=protected)
        LabelString string = ""
    end

    properties (Constant,Access=protected)
        Directions = round([sin((2*pi)*((1:12)/12))',-1*cos((2*pi)*((1:12)/12))'],8);
    end

    methods
        function graphicElementObj = GraphicalElement(element,parent)
            %GRAPHICALELEMENT Construct an instance of this class
            arguments
                element
                parent
            end
            graphicElementObj@SysMLConnector.internal.CandidateStateMachine.Element(...
                element,parent);
        end
    end

    methods(Static)
        oClock = toOClock(oClock);
    end
end

