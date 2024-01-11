function idx = getModelIndex(reset)
   persistent cachedIdx
   
   if isempty(cachedIdx) || ~isvalid(cachedIdx) || ((nargin > 0) && reset)
       cachedIdx = CandidateAD.Index;
   end

   idx = cachedIdx;
end