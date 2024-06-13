function explore(obj,candidate)
%EXPLORE explores candidate and fills the dictionary
% searches through all layers for candidate hierarchy
if iscell(candidate)
    % might be a cell array
    % explore each piece
    cellfun(@(c) obj.explore(c),candidate);
elseif isa(candidate,"dictionary")
    % need to unpack the dictionary
    % do not have to check for scalar as dictionaries must always be scalar
    if candidate.isConfigured
        % make sure its not unused
        obj.explore(candidate.values);
    end
elseif isscalar(candidate)
    if isenum(candidate) || ...
            (~isstruct(candidate) && ~isvalid(candidate))
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
            % disp(obj.dictionary.numEntries); % useful when errors occur
            obj.dictionary(candidate.ExtElementID) = {candidate};
        end
    end
    %% filter with validation function
    fields = fields(cellfun(@(f) obj.propertyValidator(f),fields));
    %% filter fields more before processing
    % first round check for invald (for any reason) and empty
    fieldsToKeep = true(size(fields));
    for i = 1:numel(fields)
        try
            fieldsToKeep(i) = ~isempty(candidate.(fields{i}));
        catch ME
            fieldsToKeep(i) = false;
        end
    end
    fields = fields(fieldsToKeep);
    % now that all should be accessible without error go on
    fields = fields( ...
        cellfun(@(f) isobject(candidate.(f)) || iscell(candidate.(f)),fields));
    fields = fields(cellfun(@(f) ~isstring(candidate.(f)),fields));
    fields = fields(cellfun(@(f) ~startsWith(class(candidate.(f),"umlmm")),fields));
    %% process the filtered fields
    cellfun(@(f) obj.explore(candidate.(f)),fields);
elseif isa(candidate,"containers.Map")
    % need to unpack the map
    obj.explore(candidate.values);
else
    % some kind of object array is expected
    arrayfun(@(c) obj.explore(c),candidate);
end
end