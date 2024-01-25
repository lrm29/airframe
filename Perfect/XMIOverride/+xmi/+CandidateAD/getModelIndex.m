function idx = getModelIndex(reset)
   persistent cachedIdx
   
   if isempty(cachedIdx) || ~isvalid(cachedIdx) || ((nargin > 0) && reset)
       cachedIdx = xmi.CandidateAD.Index;
   end

   idx = cachedIdx;
end