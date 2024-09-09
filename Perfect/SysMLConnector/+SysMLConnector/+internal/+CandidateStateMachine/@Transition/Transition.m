classdef Transition < SysMLConnector.internal.CandidateStateMachine.GraphicalElement & ...
        SysMLConnector.internal.CandidateStateMachine.Stateflow
    %TRANSITION represents transitions in the state machine

    properties (SetAccess=protected)
        Source
        Target
        StateflowObj
        Arranged = false
    end

    properties (SetAccess=protected,Dependent)
        SourceOClock
        DestinationOClock
        IsToSelf
    end

    methods
        function transitionObj = Transition(element,parent)
            %TRANSITION Construct an instance of this class
            arguments
                element umlmm.Transition
                parent SysMLConnector.internal.CandidateStateMachine.Region
            end
            transitionObj@SysMLConnector.internal.CandidateStateMachine.GraphicalElement(...
                SysMLConnector.internal.utils.getExtID(element),parent);
            if ~isempty(element.source)
                try
                    transitionObj.Source = parent.Subvertexes(...
                        SysMLConnector.internal.utils.getExtID(element.source));
                catch ME
                    if strcmp('MATLAB:dictionary:ScalarKeyNotFound',ME.identifier)
                        warning( ...
                            "SysMLConnector:internal:CandidateStateMachine:Transition",...
                            "Transition connects to unsupported element with ID %s.", ...
                            SysMLConnector.internal.utils.getExtID(element.source));
                    else
                        rethrow(ME);
                    end
                end
            end
            if ~isempty(element.target)
                try
                    transitionObj.Target = parent.Subvertexes(...
                        SysMLConnector.internal.utils.getExtID(element.target));
                catch ME
                    if strcmp('MATLAB:dictionary:ScalarKeyNotFound',ME.identifier)
                        warning( ...
                            "SysMLConnector:internal:CandidateStateMachine:Transition",...
                            "Transition connects to unsupported element with ID %s.", ...
                            SysMLConnector.internal.utils.getExtID(element.target));
                    else
                        rethrow(ME);
                    end
                end
            end
            % only add transitions to connected elements if both exist
            if ~isempty(transitionObj.Source) && ~isempty(transitionObj.Target)
                transitionObj.Source.addOutgoingTransition(transitionObj);
                transitionObj.Target.addIncomingTransition(transitionObj);
            end
            %% parse the element
            if element.trigger.size > 0
                trigger = element.trigger.at(1);
                switch class(trigger)
                    case "umlmm.Trigger"
                        if ~isempty(trigger.event)
                            switch class(trigger.event)
                                case "umlmm.SignalEvent"
                                    if ~isempty(trigger.event.signal)
                                        transitionObj.LabelString = transitionObj.LabelString+...
                                            matlab.lang.makeValidName( ...
                                            string(trigger.event.signal.name));
                                    end
                                case "umlmm.CallEvent"
                                    if ~isempty(trigger.event.operation)
                                        transitionObj.LabelString = transitionObj.LabelString + ...
                                            matlab.lang.makeValidName( ...
                                            string(trigger.event.operation.name));
                                    end
                                otherwise
                                    warning( ...
                                        "SysMLConnector:internal:CandidateStateMachine:Transition",...
                                        "Unsupported trigger event type %s.", ...
                                        class(trigger.event));
                            end
                        end
                    otherwise
                        warning( ...
                            "SysMLConnector:internal:CandidateStateMachine:Transition",...
                            "Unsupported trigger type %s.", ...
                            class(trigge));
                end
            end
            if ~isempty(element.guard)
                if ~isempty(element.guard.specification)
                    if element.guard.specification.body.size > 0
                        transitionObj.LabelString = transitionObj.LabelString + ...
                            "["+string(element.guard.specification.body.at(1)+"]");
                        if element.guard.specification.body.size > 1
                            warning( ...
                                "SysMLConnector:internal:CandidateStateMachine:Transition",...
                                "Guard contained %d body elements, this is not expected please contact MathWorks.", ...
                                element.guard.specification.body.size);
                        end
                    end
                end
            end
            if ~isempty(element.effect)
                switch class(element.effect)
                    case "umlmm.OpaqueBehavior"
                        if element.effect.body.size > 0
                            body = element.effect.body.at(1);
                            transitionObj.LabelString = transitionObj.LabelString+...
                                "{"+string(body)+"}";
                        end
                    case "umlmm.Activity"
                        transitionObj.LabelString = transitionObj.LabelString+...
                            "{"+string(element.effect.name)+"}";
                    otherwise
                        warning( ...
                            "SysMLConnector:internal:CandidateStateMachine:Transition",...
                            "Unsupported effect event type %s.", ...
                            class(element.effect));
                end
            end
        end

        function value = get.SourceOClock(this)
            arguments
                this SysMLConnector.internal.CandidateStateMachine.Transition
            end
            if isempty(this.StateflowObj)
                % not built yet
                value = [];
            else
                value = this.StateflowObj.SourceOClock;
            end
        end

        function value = get.DestinationOClock(this)
            arguments
                this SysMLConnector.internal.CandidateStateMachine.Transition
            end
            if isempty(this.StateflowObj)
                % not built yet
                value = [];
            else
                value = this.StateflowObj.DestinationOClock;
            end
        end

        function IsToSelf = get.IsToSelf(this)
            arguments
                this SysMLConnector.internal.CandidateStateMachine.Transition
            end
            if ~isempty(this.Source) && ~isempty(this.Target)
                IsToSelf = this.Source == this.Target;
            else
                IsToSelf = false;
            end
        end

        build(this);
        arrange(this,options);
        print(this,printer);
        %% TODO: add align label to position the label
    end
end

