function unloadElements()
%CLEANUP cleans up everything that we can
systemcomposer.allocation.AllocationSet.closeAll;
bdclose('all');
Simulink.data.dictionary.closeAll('-discard');
slreq.clear;
systemcomposer.profile.Profile.closeAll;
end