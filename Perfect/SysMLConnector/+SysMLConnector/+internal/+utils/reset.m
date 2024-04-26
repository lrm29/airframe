function reset
    % Reset functions that use caching for performance.
    SysMLConnector.internal.CandidateElement.idMap("reset");
    SysMLConnector.internal.utils.getBlockPropertyType(Reset=true);
    SysMLConnector.internal.utils.getStereotypePropertyTypeID(Reset=true);
    SysMLConnector.internal.utils.getStereotypePropertyValue(Reset=true);
    SysMLConnector.internal.utils.getSyncElementID(Reset=true);
end