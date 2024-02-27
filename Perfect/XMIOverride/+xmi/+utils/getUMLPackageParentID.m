function parentPackageID = getUMLPackageParentID(element)
    parentPackageID = "";
    owner = element.owner;
    while parentPackageID == ""
        if isa(owner, 'umlmm.Package')
            parentPackageID = xmi.utils.getExtID(owner);
        end
        owner = owner.owner;
    end
    assert(parentPackageID ~= "");
end