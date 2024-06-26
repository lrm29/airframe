function fragment = addFragment(this,element)
%ADDFRAGMENT adds a new fragment to the interaction
fragment = SysMLConnector.internal.CandidateInteraction.Fragment(this,this,element);
this.Fragments = [this.Fragments, fragment];
end

