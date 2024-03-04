function reset
    % Reset functions that use caching for performance.
    SysMLImport.internal.CandidateElement.idMap("reset");
    SysMLImport.internal.utils.getStereotypePropertyTypeID(Reset=true);
    SysMLImport.internal.utils.getStereotypePropertyValue(Reset=true);
    SysMLImport.internal.utils.getSyncElementID(Reset=true);
end