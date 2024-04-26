function pin = addPin(activityPath, pinName, isInput)
    adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;
    pin = adCommands.addPin(activityPath, pinName, isInput);

    % <ProductSupportPackage><Protect/></ProductSupportPackage>
end