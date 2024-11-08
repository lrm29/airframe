function linkTarget = getInterfaceLinkTarget(candidateInterface)
    try
        linkTarget = candidateInterface.BuiltElement.Owner.ddConn.getSection('Design Data').getEntry(candidateInterface.BuiltElement.Name);
    catch
        linkTarget = [];
    end

    % <ProductSupportPackage><Protect/></ProductSupportPackage>
end