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
    this.BuiltElement.DestinationOClock = options.destinationOClock;
end
if ~isempty(options.sourceOClock)
    this.BuiltElement.SourceOClock = options.sourceOClock;
end
% before setting the mid point it looks nicer for transition to self if the
% transition OClocks differ slightly
if this.IsToSelf
    oldDestinationOClock = this.BuiltElement.DestinationOClock;
    this.BuiltElement.DestinationEndpoint = ...
        this.BuiltElement.DestinationEndpoint+...
        5*this.Directions(this.toOClock(this.BuiltElement.DestinationOClock+3),:);
    % alter the source OClock to look nice too
    deltaOClock = this.BuiltElement.DestinationOClock -oldDestinationOClock;
    this.BuiltElement.SourceOClock = this.BuiltElement.SourceOClock - deltaOClock;
end
if ~isempty(options.midPoint)
    this.BuiltElement.MidPoint = options.midPoint;
end
end