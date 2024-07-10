function build(this)
%BUILD builds the junctions
arguments
    this SysMLConnector.internal.CandidateStateMachine.Junction
end
this.StateflowObj = Stateflow.Junction(this.Parent.StateflowObj);
% handle special cases
switch this.Type
    case "initial"
        % this is the node to start arranging from
        this.IsStart = true;
        % initial node needs a default transition
        defaultTransition = Stateflow.Transition(this.Parent.StateflowObj);
        defaultTransition.Destination = this.StateflowObj;
        defaultTransition.SourceEndPoint = this.Center-[0,this.Height]-...
            [0 this.DefaultOffset/4];
        defaultTransition.MidPoint = this.Center-[0,this.Height]-...
            [0 this.DefaultOffset/8];
        defaultTransition.DestinationOClock = 0;
    otherwise
        % no special handling required
end
end