function [isNotCompatible, errorID, errorMsg] = mustBeCompatibleVersionOrLater(options)
    arguments
        options.ErrorLevel (1,:) char {mustBeMember(options.ErrorLevel, {'none', 'warn', 'error'})} = 'warn'
    end

    errorID = "";
    errorMsg = "";

    [release, update] = SysMLConnector.internal.utils.getCompatibleVersion;

    isNotCompatible = isMATLABReleaseOlderThan(release, "release", update);

    if isNotCompatible
        userVersion = matlabRelease;
        if update > 0
            updateStr = sprintf(' Update %i', update);
        else
            updateStr = '';
        end

        if userVersion.Update > 0
            userUpdateStr = sprintf(' Update %i', userVersion.Update);
        else
            userUpdateStr = '';
        end

        errorID  = 'SysMLConnector:UnsupportedVersion';
        errorMsg = sprintf('The recommended MATLAB release for this version of the SysML Connector is %s%s but you are currently using %s%s.', release, updateStr, userVersion.Release, userUpdateStr);

        switch options.ErrorLevel
            case 'warn'
                warning(errorID, errorMsg); %#ok<SPWRN>
            case 'error'
                error(errorID, errorMsg); %#ok<SPERR>
        end
    end
end