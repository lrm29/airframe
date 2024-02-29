function [packagedActivities, activityStructs] = getActivities(xmiFile)
    % Use regex to find any uml:Activity types in the file.
    fileContent = fileread(xmiFile);
    pattern = "<(?<tagName>doActivity|ownedBehavior)[^>]*?xmi:type='uml:Activity'[^>][^>]*?xmi:id='(?<ID>\w+)'[^>]*?>";
    matches = regexp(fileContent, pattern, 'names');

    % Read the XMI file in as an XML structure
    umlStruct = readstruct(xmiFile);
    model = umlStruct.uml_Model;
    
    % Parse the UML Model into a containers.Map that can be used for
    % referencing by XMI ID and include the handle to the database in the
    % struct.
    xmiDatabase = ADBuilder.internal.XMIDatabase(model);

    numMatches = numel(matches);
    packagedActivities = strings(0, numMatches);
    % Must be cell because not all structs from the XMI have the same list
    % of fields.
    activityStructs    = cell.empty(0, numMatches);

    % Return each of the activity structs
    for activityIdx = 1:numMatches
        activity = matches(activityIdx);
        activityStruct = xmiDatabase.lookup(activity.ID);
        activityStruct.XMI_Database = xmiDatabase;
        
        activityStructs{activityIdx} = activityStruct;
        packagedActivities(activityIdx) = xmiDatabase.getElementPath(activity.ID);
    end
end