function parentPackageID = getUMLPackageParentID(element)
    parentPackageID = "";
    owner = element.owner;
    while parentPackageID == ""
        if isa(owner, 'umlmm.Package')
            parentPackageID = SysMLImport.internal.utils.getExtID(owner);
        end
        owner = owner.owner;
    end
    assert(parentPackageID ~= "");
end