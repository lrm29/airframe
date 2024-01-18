function flow = addFlow(source, destination, NameValueArgs)
    arguments
        source                    % CandidateAD.Element
        destination               % CandidateAD.Element
        NameValueArgs.Guard = ''
    end

    flow = ADBuilder.internal.addZCActivityFlow(source.ZCElement, destination.ZCElement, Guard=NameValueArgs.Guard);
end