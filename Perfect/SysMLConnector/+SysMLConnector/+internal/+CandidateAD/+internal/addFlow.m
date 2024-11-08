function flow = addFlow(source, destination, NameValueArgs)
    arguments
        source                    % CandidateAD.Element
        destination               % CandidateAD.Element
        NameValueArgs.Guard = ''
    end

    flow = SysMLConnector.internal.CandidateAD.internal.addZCActivityFlow(source.BuiltElement, destination.BuiltElement, Guard=NameValueArgs.Guard);
end