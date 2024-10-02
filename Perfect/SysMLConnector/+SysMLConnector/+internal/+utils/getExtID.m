function extID = getExtID(element)
try
    extIDInfo = element.getExternalToolInfo("MagicDraw");
catch ME
    extIDInfo = [];
end
extID = "";
if ~isempty(extIDInfo)
    extID = string(extIDInfo.externalId);
end
if extID == ""
    extID = string(element.toString());
end
end