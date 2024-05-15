function cleanEnvironment
    %% cleanEnvironment - Close all open artifacts to prevent any conflicts during import. 
    %
    % WARNING: Using this function can cause data loss for unsaved work.
    %
    % Use SysMLConnector.cleanEnvironment to close all opened artifacts to
    % prevent any conflicts with files created during import or export.
    % 
    % This is useful if an import or export fails and leaves some files
    % opened or if you are getting errors about artifacts that already
    % exist but deleting the files does not resolve the issue
    %
    % Artifacts closed:
    %   Allocation Sets
    %   Models (Simulink and System Composer)
    %   Data Dictionaries
    %   Requirement and Link Sets
    %   Profiles
    %   Workspace Variables
    %
    systemcomposer.allocation.AllocationSet.closeAll;
    bdclose('all');
    Simulink.data.dictionary.closeAll('-discard');
    slreq.clear;    
    systemcomposer.profile.Profile.closeAll;
    evalin('base', 'clear(''classes'')');
    clc
end