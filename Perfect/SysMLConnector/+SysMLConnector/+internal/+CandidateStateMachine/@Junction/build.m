function build(this)
%BUILD builds the junctions
arguments
    this SysMLConnector.internal.CandidateStateMachine.Junction
end

this.BuiltElement = Stateflow.Junction(this.Owner.BuiltElement);

this.storeID();
%% handle special cases
switch this.Type
    case umlmm.PseudostateKind.Initial
        % initial node needs a default transition
        defaultTransition = Stateflow.Transition(this.Owner.BuiltElement);
        defaultTransition.Destination = this.BuiltElement;
        defaultTransition.SourceEndPoint = this.Center-[0,this.Height]-...
            [0 this.DefaultOffset/4];
        defaultTransition.MidPoint = this.Center-[0,this.Height]-...
            [0 this.DefaultOffset/8];
        defaultTransition.DestinationOClock = 0;
    otherwise
        % no special handling required
end
end