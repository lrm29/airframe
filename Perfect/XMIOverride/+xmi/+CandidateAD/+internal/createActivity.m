function activity = createActivity(activityName, openFlag)
    arguments
        activityName {mustBeValidVariableName}
        openFlag logical = true
    end

    adCommands = systemcomposer.activitydiagram.internal.ActivityCommands;

    activity = adCommands.newActivity(activityName, openFlag);
end