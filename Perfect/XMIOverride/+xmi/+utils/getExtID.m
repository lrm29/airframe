function extID = getExtID(element)
    extIDInfo = element.getExternalToolInfo("MagicDraw");
    extID = "";
    if ~isempty(extIDInfo)
        extID = string(extIDInfo.externalId);
    end
    if extID == ""
        extID = string(element.toString());
    end
end