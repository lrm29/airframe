classdef CandidateRequirement < SysMLImport.internal.CandidateElement
% CANDIDATEREQUIREMENT Helper class for SysMLImport.internal.import that holds candidate Requirements.
    properties
        Name
        ReqID
        Text
        
        ReqOwnerExtElementID
        
        ChildRequirements
        ParentRequirement
        
        ZCElement = [];
    end
    
    methods
        function this = CandidateRequirement(extElemID, reqName, reqID, txt, ownID)
            this@SysMLImport.internal.CandidateElement(extElemID);
            this.Name = reqName;
            this.ReqID = reqID;
            this.Text = txt;
            
            this.ReqOwnerExtElementID = ownID;
        end
        
        function link(this)
            if this.ReqOwnerExtElementID ~= ""
                parReq = SysMLImport.internal.CandidateElement.idMap(...
                    "lookup", this.ReqOwnerExtElementID);
                parReq.ChildRequirements = [parReq.ChildRequirements this];
                this.ParentRequirement = parReq;
            end
        end
                
        function print(this, printer)
            printer.openScope("Req: " + this.ReqID  + " -- " + ...
                              this.Text);
            
            for k = 1:length(this.ChildRequirements)
                this.ChildRequirements(k).print(printer);
            end
            
            printer.closeScope("Req: " + this.ReqID);
        end
    end
end
