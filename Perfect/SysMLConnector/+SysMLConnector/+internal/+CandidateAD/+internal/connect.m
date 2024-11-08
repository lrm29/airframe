function flow = connect(source, destination, guard, externalID)
    if isa(source.Owner, 'SysMLConnector.internal.CandidateAD.Model')
        parent = source.Owner;
    else
        parent = source.Owner.Owner;
    end

    flow = SysMLConnector.internal.CandidateAD.Flow(guard, source.ExternalID, destination.ExternalID, Name='Conn', ExternalID=externalID, Owner=parent);

    parent.Flows = [parent.Flows flow];
end