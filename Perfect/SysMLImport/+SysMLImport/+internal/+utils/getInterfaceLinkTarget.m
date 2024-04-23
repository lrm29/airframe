function linkTarget = getInterfaceLinkTarget(candidateInterface)
    try
        linkTarget = candidateInterface.ZCElement.Owner.ddConn.getSection('Design Data').getEntry(candidateInterface.ZCElement.Name);
    catch
        linkTarget = [];
    end

    % <ProductSupportPackage><Protect/></ProductSupportPackage>
end