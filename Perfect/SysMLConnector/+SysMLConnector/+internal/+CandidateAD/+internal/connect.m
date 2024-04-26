function flow = connect(source, destination, guard, externalID)
    if isa(source.Parent, 'SysMLConnector.internal.CandidateAD.Model')
        parent = source.Parent;
    else
        parent = source.Parent.Parent;
    end

    flow = SysMLConnector.internal.CandidateAD.Flow(guard, source.ExternalID, destination.ExternalID, Name='Conn', ExternalID=externalID, Parent=parent);

    parent.Flows = [parent.Flows flow];
end