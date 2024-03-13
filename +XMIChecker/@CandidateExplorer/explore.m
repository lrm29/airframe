function explore(obj,candidate)
%EXPLORE explores candidate and fills the dictionary
% searches through all layers for candidate hierarchy
if isscalar(candidate)
    if ~isstruct(candidate) && ~isvalid(candidate)
        % invalid stop digging
        return;
    end
    fields = fieldnames(candidate);
    if ismember("ExtElementID",fields)
        % check if it has been explored (assuming there aren't duplicates)
        if obj.dictionary.isConfigured &&...
                ismember(candidate.ExtElementID,obj.dictionary.keys)
            % stop exploring to prevent looping
            return;
        else
            % means this has an ExtElementID, add to the dictionary
            obj.dictionary(candidate.ExtElementID) = {candidate};
        end
    end
    for i = 1:numel(fields)
        if isobject(candidate.(fields{i})) && ~isstring(candidate.(fields{i}))
            % this field has an object assume its a candidate
            obj.explore(candidate.(fields{i}));
        end
    end
elseif iscell(candidate)
    % might be a cell array
    % explore each piece
    cellfun(@(c) obj.explore(c),candidate);
elseif isa(candidate,"containers.Map")
    % need to unpack the map
    obj.explore(candidate.values);
else
    % some kind of object array is expected
    arrayfun(@(c) obj.explore(c),candidate);
end
end