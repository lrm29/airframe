function arrange(this)
%ARRANGE arranges this node and connected ones
arguments
    this SysMLConnector.internal.CandidateStateMachine.Node
end
% record that arrange was called
this.ArrangeCount = this.ArrangeCount + 1;
if this.ArrangeCount < 2
    % assume that all of the incoming transitions are fine as is
    clockStep = min(max(floor(12/this.ConnectionCount),1),3);
    % find a starting outgoing direction
    if isempty(this.IncomingTransitions)
        % start at the bottom and work around
        nextOutgoingOClock = 6;
    else
        arrangedIncomingTransition = ...
            this.IncomingTransitions([this.IncomingTransitions.Arranged]);
        if isempty(arrangedIncomingTransition)
            % start at the bottom and work around
            nextOutgoingOClock = 6;
        else
            % start opposite first arranged incoming transition
            nextOutgoingOClock = ...
                SysMLConnector.internal.CandidateStateMachine.Node.toOClock(...
                arrangedIncomingTransition(1).DestinationOClock+6);
        end
    end
    for i = 1:numel(this.OutgoingTransitions)
        % first check for transition to self
        if this.OutgoingTransitions(i).IsToSelf
            % I connect to myself, use a single connection point
            nextOutgoingOClock = findAvailableOutgoingOClock( ...
                this,nextOutgoingOClock,1);
            this.OutgoingTransitions(i).arrange( ...
                destinationOClock=nextOutgoingOClock, ...
                sourceOClock=nextOutgoingOClock,...
                midPoint=...
                this.Center + ...
                computeOffset(this,nextOutgoingOClock));
        else
            if this.OutgoingTransitions(i).Target.ArrangeCount < 1
                % set the next outgoing transition position
                nextOutgoingOClock = findAvailableOutgoingOClock( ...
                    this,nextOutgoingOClock,clockStep);

                % find the offset
                offset = computeOffset(this,nextOutgoingOClock);

                % move the next node
                this.OutgoingTransitions(i).Target.moveCenterTo( ...
                    this.Center+offset);
                % move the incoming position
                arrangeTransition( ...
                    this,this.OutgoingTransitions(i),nextOutgoingOClock);
                % arrange that section of the state machine
                this.OutgoingTransitions(i).Target.arrange();
            else
                % if the next node has been moved I don't get to move it
                % here
                % have to compute the direction of the next node and move
                % the connection points to match
                differenceVector = ...
                    this.OutgoingTransitions(i).Target.Center-this.Center;
                % invert the y axis value to correct for coordinate system
                pointToOClock = this.toOClock( ...
                    atan2(differenceVector(1),-1*differenceVector(2))/(pi/6));
                pointToOClock = this.findNearestUnusedOClock(pointToOClock);
                % need to find an opening on the other end
                arrangeTransition( ...
                    this,this.OutgoingTransitions(i),pointToOClock);
            end

            % increment the next position
            nextOutgoingOClock = this.toOClock(nextOutgoingOClock+clockStep);
        end
    end
else
    %% TODO: follow up passes
end
end

function arrangeTransition(this,transition,oClock)
arguments
    this SysMLConnector.internal.CandidateStateMachine.Node
    transition SysMLConnector.internal.CandidateStateMachine.Transition
    oClock (1,1) {mustBeNumeric}
end
transition.arrange( ...
    sourceOClock=oClock,...
    destinationOClock=...
    transition.Target.findNearestUnusedOClock( ...
    transition.Target.findClosestOClock( ...
    this.getOClockPosition(oClock))));
end

function nextOutgoingOClock = findAvailableOutgoingOClock(...
    this,nextOutgoingOClock,clockStep)
arguments
    this SysMLConnector.internal.CandidateStateMachine.Node
    nextOutgoingOClock (1,1) {mustBeNumeric}
    clockStep (1,1) {mustBeNumeric}
end
if this.OClocksInUse(nextOutgoingOClock)
    % there is a conflict
    % the position is in use
    options = this.toOClock(nextOutgoingOClock + clockStep:clockStep:12);
    goodOptions = this.toOClock(options(this.OClocksInUse(options)));
    if isempty(goodOptions)
        % no options found try again with smaller step size
        if clockStep > 1
            nextOutgoingOClock = findAvailableOutgoingOClock( ...
                this,nextOutgoingOClock,1);
        else
            % no good options just give up
            return;
        end
    else
        % take the first one
        nextOutgoingOClock = goodOptions(1);
    end
end
end

function offset = computeOffset(this,OClock)
arguments
    this SysMLConnector.internal.CandidateStateMachine.Node
    OClock {mustBeNumeric}
end
magnitude = max(sum(sqrt((this.Center-this.getOClockPosition(OClock)).^2)), ...
    this.DefaultOffset);
offset = this.Directions(OClock,:)*magnitude;
end