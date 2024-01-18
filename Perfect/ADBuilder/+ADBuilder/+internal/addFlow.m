function flow = addFlow(source, destination, NameValueArgs)
    arguments
        source                    % CandidateAD.Element
        destination               % CandidateAD.Element
        NameValueArgs.Target = [] % CandidateAD.Element
        NameValueArgs.Guard = ''
    end

    adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;
    
    if isempty(NameValueArgs.Target)
        if ~isa(source, 'CandidateAD.Pin') || isa(source.Parent, 'CandidateAD.Model')
            target = source.Parent;
        else
            target = source.Parent.Parent;
        end
    else
        target = NameValueArgs.Target;
    end

    targetPath = ADBuilder.internal.getQualifiedName(target);

    try
        flow = adCommands.addFlow(targetPath,        ...
                                  toEndPath(source), ...
                                  toEndPath(destination));
    catch
        % Assume the addFlow failed due to known issue of slashes in the
        % name. This is a performance hit so only try it as a last resort.
        cleanName(source);
        cleanName(destination);

        flow = adCommands.addFlow(targetPath,        ...
                                  toEndPath(source), ...
                                  toEndPath(destination));
        restoreName(source);
        restoreName(destination);
    end

    if ~isempty(NameValueArgs.Guard)
        setGuard(flow, NameValueArgs.Guard);
    end
end

function endPath = toEndPath(flowEnd)
    if ~isa(flowEnd, 'CandidateAD.Parameter') && isa(flowEnd, 'CandidateAD.Pin')
        endPath = sprintf('%s/%s', flowEnd.Parent.ZCElement.Name, flowEnd.ZCElement.Name);
    else
        endPath = flowEnd.ZCElement.Name;
    end    
end

function cleanName(flowEnd)
    if ~isa(flowEnd, 'CandidateAD.Parameter') && isa(flowEnd, 'CandidateAD.Pin')
        cleanName(flowEnd.Parent);
    end   

    newName = strrep(flowEnd.ZCElement.Name, '/', 'FWD_SLASH');

    setZCName(flowEnd, newName);
end

function restoreName(flowEnd)
    if ~isa(flowEnd, 'CandidateAD.Parameter') && isa(flowEnd, 'CandidateAD.Pin')
        restoreName(flowEnd.Parent);
    end   

    newName = strrep(flowEnd.ZCElement.Name, 'FWD_SLASH', '/');

    setZCName(flowEnd, newName);
end