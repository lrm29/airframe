function build(this)
%BUILD builds the junctions
arguments
    this SysMLConnector.internal.CandidateStateMachine.PortJunction
end
if ~this.Built
    % build the port in the state which is the parent of the port which is
    % the parent of this
    this.StateflowObj = Stateflow.Port(...
        this.Parent.Parent.StateflowObj,this.PortType);
    this.StateflowObj.LabelString = num2str(this.PortNumber);
    this.storeID();
    % do not build parent here, need to arrange the junctions first
end
end