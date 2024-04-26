function cleanEnvironment
    %% cleanEnvironment - Close all open artifacts to prevent any conflicts during import. 
    %
    % WARNING: Using this function can cause data loss for unsaved work.
    %
    % Use SysMLImport.cleanEnvironment to close all opened artifacts to
    % prevent any conflicts with files created during import. This is
    % useful if an import fails and leaves some files opened. It also
    % performs a clear 'all' and clc.
    %
    % Artifacts closed:
    %   Allocation Sets
    %   Models
    %   Data Dictionaries
    %   Requirement and Link Sets
    %   Profiles
    %
    systemcomposer.allocation.AllocationSet.closeAll;
    bdclose('all');
    Simulink.data.dictionary.closeAll('-discard');
    slreq.clear;    
    systemcomposer.profile.Profile.closeAll;
    clear('all') %#ok<CLALL>
    clc
end