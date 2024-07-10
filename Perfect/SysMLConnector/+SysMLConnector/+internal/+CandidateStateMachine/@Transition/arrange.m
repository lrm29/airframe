function arrange(this,options)
%ARRANGE used to arrange the transition
arguments
    this SysMLConnector.internal.CandidateStateMachine.Transition
    options.sourceOClock {mustBeNumeric} = []
    options.destinationOClock {mustBeNumeric} = []
    options.midPoint {mustBeNumeric} = []
end
this.Arranged = true;
if ~isempty(options.destinationOClock)
    this.StateflowObj.DestinationOClock = options.destinationOClock;
end
if ~isempty(options.sourceOClock)
    this.StateflowObj.SourceOClock = options.sourceOClock;
end
% before setting the mid point it looks nicer for transition to self if the
% transition OClocks differ slightly
if this.IsToSelf
    oldDestinationOClock = this.StateflowObj.DestinationOClock;
    this.StateflowObj.DestinationEndpoint = ...
        this.StateflowObj.DestinationEndpoint+...
        5*this.Directions(this.toOClock(this.StateflowObj.DestinationOClock+3),:);
    % alter the source OClock to look nice too
    deltaOClock = this.StateflowObj.DestinationOClock -oldDestinationOClock;
    this.StateflowObj.SourceOClock = this.StateflowObj.SourceOClock - deltaOClock;
end
if ~isempty(options.midPoint)
    this.StateflowObj.MidPoint = options.midPoint;
end
end