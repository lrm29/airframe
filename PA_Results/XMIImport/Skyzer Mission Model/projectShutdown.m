profTmp = systemcomposer.profile.Profile.find('MissionTypes');
if ~isempty(profTmp); profTmp.close(true); end; clear('profTmp');
